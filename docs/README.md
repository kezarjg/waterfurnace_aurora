# WaterFurnace Aurora Documentation

Complete documentation for the WaterFurnace Aurora gem.

## Quick Navigation

**New users:** Start with [Getting Started Guide](../getting-started.md)

**Quick reference:**
- [Hardware Setup](connections/hardware.md)
- [Troubleshooting](troubleshooting.md)
- [MQTT Bridge](integration/mqtt.md)

## Documentation Structure

### 📚 Getting Started

Essential guides for new users:

- **[Getting Started Guide](../getting-started.md)** - Quick setup on Raspberry Pi
- **[Hardware Connection Guide](connections/hardware.md)** - Cable creation, wiring, and safety
- **[Installation Guide](installation.md)** - Detailed installation for all platforms

### 🏠 Integration

Connect your heat pump to home automation:

- **[MQTT Bridge](integration/mqtt.md)** - Core integration tool with Homie convention
  - MQTT broker setup
  - systemd service configuration
  - ModBus pass-through
  - Web AID Tool hosting
- **[Home Assistant](integration/home-assistant.md)** - Auto-discovery and configuration
  - Entity setup
  - Lovelace card examples
  - Automation examples
- **[OpenHAB](integration/openhab.md)** - MQTT binding integration
  - Thing configuration
  - Sitemap examples
  - Rules examples

### 🔧 Tools

Command-line and web tools:

- **[aurora_mqtt_bridge](integration/mqtt.md)** - Primary MQTT integration daemon
- **[aurora_fetch](tools/aurora_fetch.md)** - Query ModBus registers
  - Single register queries
  - Range queries
  - System dumps (YAML export)
- **[aurora_monitor](tools/aurora_monitor.md)** - Real-time bus monitoring
  - Traffic analysis
  - Change detection
  - Reverse engineering workflow
- **[aurora_mock](tools/aurora_mock.md)** - Simulated ABC server
  - Offline testing
  - Development without hardware
- **[web_aid_tool](tools/web_aid_tool.md)** - Web-based control interface
  - Browser access
  - AWL reproduction
  - Security considerations

### 🔌 Connections

How to connect to your heat pump:

- **[Serial Connection](connections/serial.md)** - Direct RS-485 connection
  - USB adapters
  - Device paths (Linux/macOS/Windows)
  - Permissions and troubleshooting
  - Raspberry Pi GPIO (advanced)
- **[Network Connection](connections/network.md)** - Serial over network
  - ser2net configuration
  - TCP raw serial
  - RFC2217 (telnet)
  - MQTT pass-through
  - Security considerations

### 💻 Development

For developers and contributors:

- **[Register Reference](development/registers.md)** - Known ModBus register mappings
  - Temperature registers
  - Control registers
  - Status flags
  - Fault codes
  - Equipment-specific registers
- **[Reverse Engineering Guide](development/reverse-engineering.md)** - Discover new features
  - Traffic monitoring workflow
  - Register discovery methods
  - Documentation guidelines
  - Contributing findings
- **[Protocol Documentation](development/protocol.md)** - ModBus technical details
  - Standard ModBus functions
  - Custom functions (65-68)
  - Packet formats
  - Error handling

### 🆘 Reference

Additional resources:

- **[Troubleshooting](troubleshooting.md)** - Common issues and solutions
- **[FAQ](faq.md)** - Frequently asked questions
- **[Glossary](glossary.md)** - Terms and abbreviations

## Documentation by Use Case

### "I want to integrate with Home Assistant"

1. [Hardware Setup](connections/hardware.md) - Build your cable
2. [Getting Started](../getting-started.md) - Install software
3. [Home Assistant Integration](integration/home-assistant.md) - Configure HA

### "I want to control via web browser"

1. [Hardware Setup](connections/hardware.md) - Build your cable
2. [Web AID Tool](tools/web_aid_tool.md) - Set up web interface
3. Download AWL assets (see web_aid_tool docs)

### "I want to integrate with OpenHAB"

1. [Hardware Setup](connections/hardware.md) - Build your cable
2. [MQTT Bridge](integration/mqtt.md) - Set up MQTT
3. [OpenHAB Integration](integration/openhab.md) - Configure OpenHAB

### "I want to query registers from command line"

1. [Hardware Setup](connections/hardware.md) - Build your cable
2. [Serial Connection](connections/serial.md) - Set up connection
3. [aurora_fetch](tools/aurora_fetch.md) - Query registers

### "I want to discover new features"

1. [Hardware Setup](connections/hardware.md) - Set up in-line monitoring
2. [aurora_monitor](tools/aurora_monitor.md) - Monitor traffic
3. [Reverse Engineering Guide](development/reverse-engineering.md) - Methodology

### "I want to run on Windows"

1. [Hardware Setup](connections/hardware.md) - Build your cable
2. [Network Connection](connections/network.md) - Set up ser2net on Linux device
3. Connect from Windows via TCP

## Documentation Conventions

### File Links

- Links use relative paths
- External links open in new window (when rendered on GitHub)
- Cross-references between docs are bidirectional

### Code Examples

- Bash commands shown with `$` prompt
- Ruby code examples are complete and runnable
- YAML examples are valid syntax

### Safety Warnings

**⚠️ Warning boxes** highlight:
- Electrical safety
- Warranty concerns
- Data loss risks
- Equipment damage potential

### Version Information

Documentation is current as of gem version **1.5.8**.

Some features may vary by:
- Equipment configuration
- Firmware version
- Geographic region

## Contributing to Documentation

Documentation improvements welcome!

**How to contribute:**

1. Fork repository
2. Edit markdown files
3. Test links work
4. Submit pull request

**Style guide:**
- Use clear, concise language
- Include examples
- Link to related docs
- Test all commands
- Consider different skill levels

## Getting Help

**Documentation unclear?** Let us know!

- [GitHub Issues](https://github.com/ccutrer/waterfurnace_aurora/issues) - Report doc issues
- [GitHub Discussions](https://github.com/ccutrer/waterfurnace_aurora/discussions) - Ask questions

## Index of All Pages

### Root Level
- [README.md](../README.md) - Main project overview
- [getting-started.md](../getting-started.md) - Quick start guide
- [docker/README.md](../docker/README.md) - Docker deployment

### Integration
- [integration/mqtt.md](integration/mqtt.md) - MQTT bridge
- [integration/home-assistant.md](integration/home-assistant.md) - Home Assistant
- [integration/openhab.md](integration/openhab.md) - OpenHAB

### Tools
- [tools/aurora_fetch.md](tools/aurora_fetch.md) - Register query tool
- [tools/aurora_monitor.md](tools/aurora_monitor.md) - Traffic monitor
- [tools/aurora_mock.md](tools/aurora_mock.md) - Mock ABC server
- [tools/web_aid_tool.md](tools/web_aid_tool.md) - Web interface

### Connections
- [connections/hardware.md](connections/hardware.md) - Hardware setup and wiring
- [connections/serial.md](connections/serial.md) - Serial port connection
- [connections/network.md](connections/network.md) - Network connections

### Development
- [development/registers.md](development/registers.md) - Register reference
- [development/reverse-engineering.md](development/reverse-engineering.md) - Discovery guide
- [development/protocol.md](development/protocol.md) - Protocol details

### Reference
- [troubleshooting.md](troubleshooting.md) - Problem solving

---

**[Back to Main README](../README.md)** | **[Get Started](../getting-started.md)**
