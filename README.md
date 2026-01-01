# WaterFurnace Aurora Gem

A Ruby library for direct communication with Aurora-based WaterFurnace heat pump systems via RS-485 ModBus.

[![Gem Version](https://badge.fury.io/rb/waterfurnace_aurora.svg)](https://badge.fury.io/rb/waterfurnace_aurora)

## Overview

This gem enables local control and monitoring of WaterFurnace geothermal heat pumps that use the Aurora communication protocol. It connects directly to the RS-485 bus used by the AID Tool and Aurora Web Link (AWL), providing:

- **Direct local control** - No cloud dependency
- **Home automation integration** - MQTT with Homie/Home Assistant auto-discovery
- **Web interface** - Reproduction of the AID Tool web interface
- **Comprehensive monitoring** - Access to 200+ system registers
- **Reverse-engineered protocol** - Built from analyzing actual traffic

## Quick Start

**New to this project?** Jump right in:

- **🚀 [Getting Started Guide](getting-started.md)** - Quick setup on Raspberry Pi
- **🔧 [Hardware Setup](docs/connections/hardware.md)** - Build your RS-485 cable

Already familiar? Choose your path:

- **🏠 [Home Assistant Integration](docs/integration/home-assistant.md)**
- **📡 [MQTT Bridge Setup](docs/integration/mqtt.md)**
- **🌐 [Web AID Tool](docs/tools/web_aid_tool.md)**
- **📖 [All Documentation](docs/)**

## Features

### Control & Monitoring

- Heating/cooling setpoints
- HVAC mode (heat, cool, auto, off, emergency heat)
- Fan mode (auto, continuous, intermittent)
- Domestic hot water (if equipped)
- Humidifier/dehumidifier (if equipped)
- Multi-zone support (IntelliZone 2)

### Sensors & Diagnostics

- Air temperatures (entering/leaving)
- Water temperatures (entering/leaving)
- Power consumption (if energy monitoring equipped)
- Compressor/blower/pump status and speeds
- Water flow rate
- Fault history and current faults
- System configuration details

### Integration Options

- **MQTT**: Publish to any MQTT broker with Homie convention
- **Home Assistant**: Auto-discovery with climate, sensor, and control entities
- **OpenHAB**: MQTT binding with automatic thing creation
- **Web Interface**: Browser-based control (AWL reproduction)
- **Command Line**: Direct register queries and writes

## Installation

### Raspberry Pi (Recommended)

See the **[Getting Started Guide](getting-started.md)** for complete Raspberry Pi setup.

Quick version:
```bash
sudo apt install ruby ruby-dev
sudo gem install waterfurnace_aurora --no-doc
```

### Other Platforms

**Requirements:**
- Ruby 2.5, 2.6, or 2.7
- Linux (for direct serial port access)
- OR network connection to serial port server

**Install:**
```bash
gem install waterfurnace_aurora
```

**Debian/Ubuntu dependencies:**
```bash
sudo apt install ruby ruby-dev
```

### Docker

See **[docker/README.md](docker/README.md)** for containerized deployment.

```bash
docker build -t ccutrer/waterfurnace_aurora https://github.com/ccutrer/waterfurnace_aurora.git\#main:docker
docker run -d --device=/dev/ttyUSB0 --env TTY=/dev/ttyUSB0 --env MQTT=mqtt://localhost ccutrer/waterfurnace_aurora
```

## Tested Equipment

This gem has been tested with:

- WaterFurnace 7 Series (IntelliZone 2, DHW, ECM blower, VS Drive, VS Pump)
- WaterFurnace 5 Series (ECM blower, split system configurations)
- WaterFurnace Versatec Base
- GeoSmart PremiumV (DHW, ECM blower, VS Drive, VS Pump)

**Note:** Systems with pre-AWL firmware may have limited data availability. See [WaterFurnace Symphony documentation](https://www.waterfurnace.com/literature/symphony/ig2001ew.pdf).

## Documentation

### Getting Started
- **[Getting Started Guide](getting-started.md)** - Raspberry Pi quick setup
- **[Hardware Connection Guide](docs/connections/hardware.md)** - Cable creation and wiring
- **[Installation](docs/installation.md)** - Detailed installation for all platforms

### Integration
- **[MQTT Bridge](docs/integration/mqtt.md)** - MQTT broker setup and configuration
- **[Home Assistant](docs/integration/home-assistant.md)** - Auto-discovery and Lovelace cards
- **[OpenHAB](docs/integration/openhab.md)** - MQTT binding and sitemap examples

### Tools
- **[aurora_mqtt_bridge](docs/integration/mqtt.md)** - Primary integration tool
- **[aurora_fetch](docs/tools/aurora_fetch.md)** - Query registers
- **[aurora_monitor](docs/tools/aurora_monitor.md)** - Monitor bus traffic
- **[aurora_mock](docs/tools/aurora_mock.md)** - Simulate ABC for testing
- **[web_aid_tool](docs/tools/web_aid_tool.md)** - Web-based interface

### Connections
- **[Serial Connection](docs/connections/serial.md)** - Direct RS-485 setup
- **[Network Connection](docs/connections/network.md)** - TCP, RFC2217, MQTT pass-through

### Development
- **[Register Reference](docs/development/registers.md)** - Known ModBus registers
- **[Reverse Engineering](docs/development/reverse-engineering.md)** - Discover new registers
- **[Protocol Documentation](docs/development/protocol.md)** - ModBus extensions

### Reference
- **[Complete Documentation Index](docs/README.md)** - All documentation
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

## Community & Support

### Getting Help

- **[GitHub Issues](https://github.com/ccutrer/waterfurnace_aurora/issues)** - Bug reports and feature requests
- **[GitHub Discussions](https://github.com/ccutrer/waterfurnace_aurora/discussions)** - Questions and community discussion
- **[Troubleshooting Guide](docs/troubleshooting.md)** - Common problems

### Contributing

Contributions are welcome! Especially:

- Testing with different equipment configurations
- Discovering new registers (see [Reverse Engineering Guide](docs/development/reverse-engineering.md))
- Documentation improvements
- Bug fixes and feature enhancements

**Sharing your system dump helps development:**
```bash
aurora_fetch /dev/ttyUSB0 valid --yaml > my_system.yml
# Share via GitHub issue (redact serial if desired)
```

## How It Works

### Protocol

WaterFurnace uses a ModBus RTU-based protocol with custom extensions:
- Standard ModBus functions for basic operations
- Custom functions (65-68) for efficient bulk queries
- 19200 baud, even parity, 8 data bits, 1 stop bit

All register mappings were reverse-engineered through:
- Traffic capture between AID Tool/AWL and ABC
- Analysis of AWL web interface code
- Community testing and validation

See [Protocol Documentation](docs/development/protocol.md) for technical details.

### Architecture

```
[Heat Pump ABC] ←(RS-485)→ [Your Computer] ←(MQTT/HTTP)→ [Home Automation]
```

**Components:**
- **ABCClient**: Core library for ABC communication
- **ModBus Extensions**: Custom function codes 65-68
- **Register Mappings**: 200+ documented registers
- **Component System**: Polymorphic support for equipment variants
- **MQTT Bridge**: Homie convention publisher/subscriber
- **Web AID Tool**: Sinatra-based web interface

See [Architecture Documentation](docs/architecture.md) for details.

## Supported Equipment Variants

### Compressors
- Single-stage fixed-speed
- Dual-stage fixed-speed
- Variable Speed Drive (VS Drive) - 12 stages

### Blowers
- PSC (Permanent Split Capacitor)
- ECM (Electronically Commutated Motor) - 12 speeds
- 5-Speed PSC

### Pumps
- Fixed-speed
- Variable Speed (VS Pump) - 1-100%

### Systems
- IntelliZone 2 (IZ2) multi-zone
- AXB expansion module
- Domestic Hot Water (DHW)
- AOC/MOC cards
- Humidifier/dehumidifier

## Safety & Warranty

**⚠️ Important Warnings:**

- This software is **unofficial** and **unsupported** by WaterFurnace
- Direct communication may **void warranty**
- Incorrect commands could **damage equipment**
- **Use at your own risk**

**Recommendations:**
- Start with read-only monitoring
- Test changes carefully
- Keep AID Tool/AWL as backup control
- Know how to reset to factory defaults
- Consult HVAC professional if unsure

See [Hardware Guide](docs/connections/hardware.md) for electrical safety information.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

**Author:** Cody Cutrer

**Contributors:** Community members who have shared equipment dumps, discovered registers, and provided feedback.

**Thanks to:**
- WaterFurnace for building quality geothermal systems
- RModBus gem for ModBus foundation
- Home automation community for integration testing

## Version

Current version: **1.5.8**

See [CHANGELOG](CHANGELOG.md) for release history.

---

**Ready to get started?** Head to the **[Getting Started Guide](getting-started.md)**!
