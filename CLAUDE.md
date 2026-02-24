# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ruby gem (`waterfurnace_aurora`) for communicating with WaterFurnace Aurora-based heat pump systems over RS-485/ModBus. The protocol is a proprietary extension of ModBus using custom function codes (65-68) for reading/writing discontiguous register ranges. The gem provides an MQTT bridge (Homie convention) for home automation integration (Home Assistant, OpenHAB).

## Commands

- **Lint:** `bundle exec rubocop` (CI runs this on Ruby 3.3)
- **Build gem:** `bundle exec rake build`
- **Install deps:** `bundle install`
- **No test suite exists** — there are no spec/test directories

## Architecture

### Core Communication Layer

`Aurora::ModBus::Slave` (lib/aurora/modbus/slave.rb) — Extends RModBus with WaterFurnace's proprietary function codes:
- Function 65 (`A`): Read multiple discontiguous register ranges (pairs of addr+length)
- Function 66 (`B`): Read multiple discontiguous individual registers (list of addrs)
- Function 67: Write multiple discontiguous registers (pairs of addr+value)
- `WFProxy` overrides `holding_registers[]` to use multi-register reads when given multiple keys

`Aurora::ModBus::Server` (lib/aurora/modbus/server.rb) — Server-side parsing for the same custom functions, used by `aurora_monitor` and `aurora_mock`.

### ABCClient — Central Orchestrator

`Aurora::ABCClient` (lib/aurora/abc_client.rb) is the main entry point. On initialization it:
1. Opens a ModBus connection (serial, TCP, RFC2217, MQTT passthrough, or YAML mock file — determined by URI scheme)
2. Reads identification registers to detect model, serial number, firmware, and installed components
3. Instantiates the correct component subclasses based on detected hardware (program code determines VSDrive vs GenericCompressor, register values determine ECM vs FiveSpeed vs PSC blower, etc.)
4. Builds `@registers_to_read` — a consolidated list of all registers needed per refresh cycle
5. `refresh` reads all registers in one batch, transforms values, and delegates to each component's `refresh`

Key hardware detection patterns:
- Program codes `ABCVSP`, `ABCVSPR`, `ABCSPLVS` → `Compressor::VSDrive` (12-speed variable); otherwise `Compressor::GenericCompressor` (1-2 stage)
- Register 404 value → `Blower::ECM`, `Blower::FiveSpeed`, or `Blower::PSC`
- Register 413 value 3-5 → `Pump::VSPump`; AXB present → `Pump::GenericPump`
- AWL-compliant firmware versions gate availability of many registers (thermostat >= 3.0, IZ2 >= 2.0, AXB >= 2.0)

### Component Hierarchy

All components extend `Aurora::Component` (lib/aurora/component.rb), which holds a reference to the parent `ABCClient`. Each component implements:
- `registers_to_read` — registers it needs during each refresh cycle
- `refresh(registers)` — extracts its state from the transformed register hash

```
Component
├── Thermostat (single-zone, non-IZ2)
│   └── IZ2Zone (IntelliZone 2 multi-zone, register bases offset by zone_number)
├── Compressor::GenericCompressor (single/dual stage)
│   └── Compressor::VSDrive (variable speed, adds VS-specific registers 3xxx)
├── Blower::PSC
│   ├── Blower::FiveSpeed
│   └── Blower::ECM (configurable speed presets via registers 340-347)
├── Pump::GenericPump
│   └── Pump::VSPump (variable speed, min/max/manual control)
├── AuxHeat
├── DHW (domestic hot water)
└── Humidistat (humidifier + dehumidifier modes)
```

### Register System

`Aurora::Registers` (lib/aurora/registers.rb) contains:
- `REGISTER_NAMES` — maps register numbers to human-readable names
- `REGISTER_CONVERTERS` — maps transformation lambdas to register sets (e.g., `TO_TENTHS`, `TO_SIGNED_TENTHS`, bitmask parsers, multi-register string extraction)
- `REGISTER_FORMATS` — printf-style display formats per register
- `REGISTER_RANGES` — all valid register address ranges the ABC will respond to
- `transform_registers` — applies converters; handles both 1-arg (value-only) and 2-arg (registers-hash + index) converters for multi-register values
- `normalize_ranges` — breaks register lists into ≤100-register chunks (ABC hardware limit) respecting `REGISTER_BREAKPOINTS`

Register numbers use Ruby's underscore separator for readability (e.g., `31_003`, `12_606`). IZ2 zone registers are computed from a base + `(zone_number - 1) * offset`.

### Executables (exe/)

- `aurora_mqtt_bridge` — Main daemon: creates `ABCClient`, connects to MQTT broker, publishes Homie-convention topics, supports ModBus passthrough via `$modbus` topic, optionally runs `WebAIDTool` (Sinatra)
- `aurora_fetch` — CLI tool to query specific registers and print/dump as YAML
- `aurora_monitor` — Passive bus sniffer using `ModBus::RTUServer` in promiscuous mode
- `aurora_mock` — Serves a YAML register dump as a simulated ABC
- `web_aid_tool` — Standalone Sinatra app reproducing the AWL web AID tool interface

### MockABC

`Aurora::MockABC` (lib/aurora/mock_abc.rb) — Drop-in replacement for a real ModBus slave, backed by a YAML hash of register values. Used when a file path is given instead of a serial/network URI. Enables offline development and testing.

## Code Style

- Rubocop with `rubocop-inst` base config and `rubocop-rake`
- Target Ruby version: 2.5 (per `.rubocop.yml`)
- `frozen_string_literal: true` on all files
- `Naming/InclusiveLanguage` disabled (ModBus master/slave terminology)
- `Style::Documentation` disabled
- Bitwise operations and hex constants are used extensively for register parsing — preserve the `0x` notation and bitmask patterns
