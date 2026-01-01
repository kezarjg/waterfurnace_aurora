# aurora_mock

A tool that simulates an Aurora Base Control (ABC) unit using a YAML dump file, allowing testing without a real heat pump.

## Purpose

`aurora_mock` is useful for:
- **Development**: Test code changes without hardware
- **AID Tool testing**: Interact with AID Tool interface offline
- **Demonstrations**: Show functionality without real equipment
- **Debugging**: Reproduce issues from user dumps
- **Experimentation**: Try changes safely before applying to real system

## Usage

```bash
aurora_mock <yaml_file> <serial_port_or_tcp>
```

**Parameters:**
- `<yaml_file>`: YAML dump created by `aurora_fetch`
- `<serial_port_or_tcp>`: Where to serve the mock ABC

## Creating a Dump File

First, create a YAML dump of your system (or use someone else's):

```bash
aurora_fetch /dev/ttyUSB0 valid --yaml > my_system.yml
```

See [aurora_fetch](aurora_fetch.md) for details.

## Basic Usage

### Serial Port Mock

Serve mock ABC on a virtual serial port:

```bash
# Linux: use socat to create virtual serial ports
socat -d -d pty,raw,echo=0 pty,raw,echo=0

# Note the two PTY devices created, e.g., /dev/pts/3 and /dev/pts/4
# Then run:
aurora_mock my_system.yml /dev/pts/3

# In another terminal, connect tools to /dev/pts/4
aurora_fetch /dev/pts/4 745
```

### TCP Mock

Serve mock ABC over TCP (easier setup):

```bash
aurora_mock my_system.yml tcp://0.0.0.0:2000
```

Then connect from any tool:

```bash
aurora_fetch tcp://localhost:2000 745
web_aid_tool tcp://localhost:2000
```

## Use Cases

### Testing AID Tool Offline

1. Create dump from your real system
2. Start mock server
3. Connect AID Tool to mock server
4. Interact with AID Tool without affecting real heat pump

**Setup:**

```bash
# Start mock on network
aurora_mock my_7series.yml tcp://0.0.0.0:2000

# Point AID Tool at your computer's IP
# Configure AID Tool: tcp://192.168.1.100:2000
```

### Web AID Tool Development

Test web AID tool changes:

```bash
# Terminal 1: Start mock
aurora_mock test_system.yml tcp://localhost:2000

# Terminal 2: Start web AID tool
web_aid_tool tcp://localhost:2000
```

Browse to `http://localhost:4567` and interact with mock data.

### Code Development

Test library changes without hardware:

```ruby
require 'aurora'

# Connect to mock instead of real ABC
abc = Aurora::ABCClient.new('tcp://localhost:2000')
abc.refresh

puts "Heating setpoint: #{abc.zones.first.heating_setpoint}"

# Make changes to mock data (edits YAML in memory)
abc.zones.first.heating_setpoint = 72
```

### Reproducing User Issues

When users report issues:

1. Ask them to provide dump:
   ```bash
   aurora_fetch /dev/ttyUSB0 valid --yaml > issue_report.yml
   ```
2. They send you `issue_report.yml`
3. You run mock with their data:
   ```bash
   aurora_mock issue_report.yml tcp://localhost:2000
   ```
4. Reproduce and debug the issue

### Multi-System Testing

Test with different equipment configurations:

```bash
# Test 7 Series with VS Drive
aurora_mock 7series_vsdrive.yml tcp://localhost:2001

# Test 5 Series basic
aurora_mock 5series_basic.yml tcp://localhost:2002

# Test with IZ2
aurora_mock iz2_system.yml tcp://localhost:2003
```

## Behavior

### Read Operations

Mock responds to register reads with values from YAML file:

```bash
$ aurora_fetch tcp://localhost:2000 745
Heating Set Point (745): 68.0°F  # From YAML file
```

### Write Operations

Mock **accepts** writes but **doesn't persist** them:

```bash
# Write succeeds
aurora_mqtt_bridge tcp://localhost:2000 mqtt://localhost/
mosquitto_pub -t 'homie/aurora-XXX/$modbus/745/set' -m '700'

# Read shows new value (in memory only)
aurora_fetch tcp://localhost:2000 745
Heating Set Point (745): 70.0°F

# But original YAML file is unchanged
# Restart mock → value returns to 68.0°F
```

**Note:** This is intentional to prevent accidental modification of dump files.

### Missing Registers

If YAML doesn't contain a register, mock responds with timeout/error (same as real ABC).

## Limitations

### No Dynamic Behavior

Mock is static—it doesn't simulate:
- System state changes over time
- Sensors updating
- Compressor cycling
- Temperature changes
- Faults occurring

Values stay constant unless written via ModBus.

### No Validation

Mock doesn't enforce:
- Valid value ranges
- Logical constraints (e.g., heating > cooling setpoint)
- Equipment compatibility
- DIP switch configurations

You can write nonsensical values without errors.

### Not for AWL Testing

Mock has only been tested with AID Tool, not Aurora Web Link (AWL). AWL may expect additional behavior not implemented in the mock.

### No Session Persistence

All write changes are lost when mock restarts. Each session starts fresh from YAML file.

## Troubleshooting

### Mock Won't Start

**Port already in use:**
```
Error: Address already in use
```

**Solution:** Use different port or kill process using port:
```bash
# Find process
lsof -i :2000

# Kill it
kill <PID>
```

**Permission denied on serial port:**

Use a virtual port pair or TCP instead.

### Tools Can't Connect

1. Verify mock is running
2. Check firewall (for TCP)
3. Verify correct host/port
4. Try `telnet localhost 2000` to test connection

### No Response from Mock

1. Check YAML file is valid:
   ```bash
   ruby -ryaml -e "YAML.load_file('my_system.yml')"
   ```
2. Check registers exist in YAML
3. Check mock logs for errors

### Slow Performance

YAML loading may be slow for very large dumps. Consider:
- Use `known` instead of `valid` when creating dumps
- Remove unnecessary registers from YAML

## Advanced Usage

### Modifying Mock Data

Edit YAML file before starting mock:

```yaml
---
745: 720  # Change heating setpoint to 72.0°F
746: 680  # Change cooling setpoint to 68.0°F
```

Then start mock with modified file.

### Scripted Testing

Automate tests with different configurations:

```bash
#!/bin/bash
for config in configs/*.yml; do
  echo "Testing with $config"
  aurora_mock "$config" tcp://localhost:2000 &
  MOCK_PID=$!

  # Run tests
  ./run_tests.sh tcp://localhost:2000

  # Kill mock
  kill $MOCK_PID
  wait $MOCK_PID
done
```

### Docker Mock

Create a mock ABC in Docker:

```dockerfile
FROM ruby:2.7
RUN gem install waterfurnace_aurora
COPY system_dump.yml /dump.yml
CMD ["aurora_mock", "/dump.yml", "tcp://0.0.0.0:2000"]
```

```bash
docker build -t aurora-mock .
docker run -p 2000:2000 aurora-mock
```

## Related Tools

- **[aurora_fetch](aurora_fetch.md)**: Create dump files for mock
- **[aurora_monitor](aurora_monitor.md)**: Capture real system behavior
- **[web_aid_tool](web_aid_tool.md)**: Use with mock for offline testing

## Next Steps

- [Development Guide](../development/) - Building new features
- [Testing Guide](../development/testing.md) - Automated testing (if created)
- [Hardware Guide](../connections/hardware.md) - Connect to real ABC

## Contributing Dumps

If you have a unique equipment configuration, consider sharing your dump (with serial numbers redacted) to help developers test:

```bash
# Create dump
aurora_fetch /dev/ttyUSB0 valid --yaml > my_config.yml

# Redact serial if desired (registers 105-109)
sed -i '/^105:/d; /^106:/d; /^107:/d; /^108:/d; /^109:/d' my_config.yml

# Share via GitHub issue or pull request
```

This helps ensure the library works with all equipment variants.
