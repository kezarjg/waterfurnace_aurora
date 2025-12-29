# Reverse Engineering Guide

Learn how to discover new ModBus registers and extend support for WaterFurnace Aurora systems.

## Overview

WaterFurnace provides no documentation for their ModBus protocol. All register mappings in this library were discovered through reverse engineering.

**You can help!** If you have equipment not fully supported, your contributions can improve the library for everyone.

## Background

The Aurora ABC uses a ModBus-based protocol with:
- ~200 documented registers (see [registers.md](registers.md))
- Likely hundreds more undiscovered registers
- Custom ModBus functions (65-68)
- Equipment-specific register availability

## Tools Needed

### Hardware

**For monitoring (recommended):**
- [RJ45 breakout board](https://www.amazon.com/dp/B01GNOBDPM)
- Two RS-485 connections:
  - One to heat pump
  - One to computer
  - One to AID Tool/AWL
- See [Hardware Guide](../../HARDWARE.md#in-line-monitoring-sniffing)

**For direct querying:**
- Single RS-485 connection to heat pump
- AID Tool or AWL (for comparison)

### Software

- [aurora_monitor](../tools/aurora_monitor.md) - Watch register changes
- [aurora_fetch](../tools/aurora_fetch.md) - Query specific registers
- [MQTT ModBus pass-through](../integration/mqtt.md#modbus-pass-through) - Alternative query method
- MQTT Explorer or similar - For watching MQTT topics
- Text editor - Document findings

## Method 1: Traffic Monitoring (Recommended)

### Setup

1. Connect in-line between AID Tool and ABC (see [Hardware Guide](../../HARDWARE.md))
2. Start monitoring:
   ```bash
   aurora_monitor /dev/ttyUSB0 -q | tee session.log
   ```

The `-q` (quiet) flag filters out:
- Unchanged values
- Unknown registers
- Sensor noise (frequently changing values)
- Heartbeat registers

### Workflow

1. **Establish baseline**
   ```bash
   aurora_monitor /dev/ttyUSB0 -q
   ```
   Let it run for a minute to see normal activity.

2. **Trigger one action**
   On the AID Tool or Symphony website:
   - Change ONE setting
   - Wait for monitoring output
   - Document what changed

3. **Record findings**
   ```
   Action: Changed heating setpoint from 68°F to 70°F
   Result: Register 745 changed from 680 to 700
   ```

4. **Test hypothesis**
   Write to the register and verify behavior:
   ```bash
   mosquitto_pub -t 'homie/aurora-XXX/$modbus/745/set' -m '720'
   ```
   Check if thermostat shows 72°F.

5. **Repeat for each feature**

### Example Session

```bash
$ aurora_monitor /dev/ttyUSB0 -q

# Action: Set fan to "Continuous"
2024-01-15 10:30:22 +0000 ===== read
??? (1220): 0 → 1

# Hypothesis: Register 1220 = fan mode
# Test by writing different values...

# Action: Set fan to "Auto"
2024-01-15 10:31:15 +0000 ===== read
??? (1220): 1 → 0

# Confirmed: 1220 = fan mode (0=auto, 1=continuous)
```

## Method 2: Direct Querying

When you can't monitor traffic (no AID Tool, no in-line access), query registers directly.

### Systematic Scanning

```bash
# Query known valid ranges (from registers.md)
aurora_fetch /dev/ttyUSB0 valid --yaml > baseline.yml

# Query specific ranges
aurora_fetch /dev/ttyUSB0 800-900
aurora_fetch /dev/ttyUSB0 1200-1300
```

### Compare States

```bash
# Capture baseline
aurora_fetch /dev/ttyUSB0 1200-1250 --yaml > before.yml

# Change setting on thermostat/AID tool

# Capture new state
aurora_fetch /dev/ttyUSB0 1200-1250 --yaml > after.yml

# Find differences
diff before.yml after.yml
```

### Guided Search

Use knowledge of similar systems:
- Setpoints likely near other setpoints
- Status flags often grouped together
- Equipment-specific registers in ranges (e.g., VS Drive in 200s)

## Method 3: Code Analysis

### AWL Web Interface

Early AWL units serve obfuscated JavaScript. While obfuscated, you can still extract register numbers.

```bash
# Download assets (if you have AWL)
curl https://github.com/ccutrer/waterfurnace_aurora/raw/main/contrib/grab_awl_assets.sh -L -o grab_awl_assets.sh
./grab_awl_assets.sh 192.168.1.100

# Inspect html/ directory
grep -r "7[0-9][0-9]" html/  # Look for register numbers in 700s range
```

### Firmware Updates

Firmware files (if accessible) may contain strings or data structures revealing register purposes.

**Note:** Extracting and analyzing firmware is advanced and may violate terms of service.

## Register Patterns

### Observed Conventions

**Temperature values:**
- Stored as tenths of degrees (680 = 68.0°F)
- Often signed (negative possible)
- Usually in Fahrenheit

**Flags/Status:**
- Bitmasks in single registers
- Each bit represents on/off state
- Example: Register 30 (System Outputs)
  ```
  Bit 0 (0x01): Compressor 1
  Bit 1 (0x02): Compressor 2
  Bit 2 (0x04): Reversing valve
  ...
  ```

**String values:**
- ASCII text across multiple registers
- Each register = 2 characters
- Space-padded
- Example: Model number in 92-104

**32-bit values:**
- Span two consecutive registers
- High register first, then low
- Example: Fault details in 211-218

**Version numbers:**
- Multiplied by 100 (326 = version 3.26)

### Register Ranges

Known ranges (see [registers.md](registers.md)):
- 0-99: System info, faults, status
- 88-109: Identification strings
- 200-299: VS Drive specific (if equipped)
- 300-399: Blower control
- 400-499: DHW, AXB
- 567-599: Air temperatures
- 600-699: Fault history
- 740-750: Thermostat setpoints/temps
- 800-899: IZ2 specific (if equipped)
- 1100-1199: Energy monitoring, water temps
- 1200-1299: Humidity, advanced settings

## Documentation Format

When you discover registers, document them clearly:

```markdown
### Register 1220: Fan Mode

**Access:** Read/Write
**Range:** 0-2
**Values:**
- 0: Auto
- 1: Continuous
- 2: Intermittent

**Equipment:** All
**Tested on:** 7 Series, 5 Series

**Discovery:**
- Observed via aurora_monitor
- Correlated with AID Tool fan mode selector
- Write confirmed functional
```

## Submitting Findings

### GitHub Issue

Create an issue with:
- Title: "New register discovered: [register number] - [purpose]"
- Equipment details (model, configuration)
- How you discovered it
- Test results
- Any unknown behaviors

### Pull Request

Contribute code directly:

1. Fork repository
2. Edit `lib/aurora/registers.rb`
3. Add register to `REGISTER_NAMES`:
   ```ruby
   1220 => 'Fan Mode'
   ```
4. Add any value mappings:
   ```ruby
   FAN_MODE = {
     0 => :auto,
     1 => :continuous,
     2 => :intermittent
   }.freeze
   ```
5. Test with your system
6. Submit PR with description

### YAML Dump

Share your system dump for analysis:

```bash
aurora_fetch /dev/ttyUSB0 valid --yaml > my_system.yml

# Optionally redact serial (registers 105-109)
# Then attach to GitHub issue
```

## Safety Guidelines

### What's Safe

- **Reading registers**: Safe, read-only
- **Writing known registers**: Generally safe if values are reasonable
- **Writing to new registers with small changes**: Acceptable risk

### What's Risky

- **Writing random values**: Could damage equipment
- **Writing to system configuration**: Could require professional reset
- **Bypassing safety limits**: Danger to equipment and home
- **Modifying fault settings**: Could mask serious problems

### Best Practices

1. **Start with reads only**
2. **Small value changes**: If setpoint is 70°F, try 71°F not 140°F
3. **Monitor system behavior**: Watch for unusual operation
4. **Know how to undo**: Note original value before writing
5. **Test in safe conditions**: Not during extreme weather
6. **Have backup plan**: Know how to reset to factory defaults

## Equipment Variations

Different equipment has different registers available:

**Always present:**
- ABC version (register 2)
- Serial number (105-109)
- Basic temperatures
- Fault status

**Equipment-dependent:**
- VS Drive: 200-299 range
- IZ2: 800-899 range
- AXB: Additional sensors/controls
- ECM blower: Speed controls
- DHW: 400 range

**Document equipment when sharing findings.**

## Common Discoveries Needed

### Unknown Registers

See [registers.md](registers.md) for registers marked `???`. These need investigation:

```markdown
??? (35): Value varies
??? (73): Always 682
??? (742): Usually 0
??? (743): Usually 0
??? (744): Usually 24
```

### Equipment-Specific

If you have unique equipment:
- GeoSmart models
- Newer firmware versions
- Uncommon configurations (e.g., dual fuel, multi-stage aux)

Your findings are especially valuable!

### Feature Completeness

Known features with incomplete mappings:
- Some IZ2 advanced settings
- All humidifier modes
- AOC/MOC card features
- Smart grid integration
- Some diagnostic modes

## Resources

### Internal

- [Register Reference](registers.md) - Current known registers
- [aurora_monitor](../tools/aurora_monitor.md) - Traffic monitoring tool
- [aurora_fetch](../tools/aurora_fetch.md) - Register query tool
- [Protocol Documentation](protocol.md) - ModBus extensions

### External

- [ModBus Protocol Specification](https://modbus.org/docs/Modbus_Application_Protocol_V1_1b3.pdf)
- [RS-485 Standards](https://en.wikipedia.org/wiki/RS-485)
- WaterFurnace Symphony website (for comparison testing)

### Community

- [GitHub Issues](https://github.com/ccutrer/waterfurnace_aurora/issues) - Ask questions, share findings
- [GitHub Discussions](https://github.com/ccutrer/waterfurnace_aurora/discussions) - General discussion

## Success Stories

Many current features were discovered by community members:
- DHW setpoints
- Humidity controls
- IZ2 zone management
- ECM speed settings
- Energy monitoring registers

**Your discoveries matter!**

## Next Steps

1. Set up monitoring: [aurora_monitor guide](../tools/aurora_monitor.md)
2. Start exploring: Pick one unknown feature
3. Document findings: Note what you discover
4. Share back: GitHub issue or PR
5. Iterate: Move to next feature

Happy reverse engineering!
