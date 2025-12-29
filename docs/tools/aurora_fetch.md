# aurora_fetch

A command-line tool for querying ModBus registers from your WaterFurnace heat pump.

## Purpose

`aurora_fetch` is useful for:
- Quickly checking specific register values
- Creating system dumps for debugging
- Testing connections to the ABC
- Discovering register values for reverse engineering

## Usage

```bash
aurora_fetch <connection> <query> [options]
```

**Parameters:**
- `<connection>`: Serial port, network URI, or YAML file (see [Connections](../connections/))
- `<query>`: Register specification (see [Query Syntax](#query-syntax))
- `[options]`: Output format options

## Query Syntax

### Single Register

```bash
aurora_fetch /dev/ttyUSB0 745
```

Output:
```
Heating Set Point (745): 68.0°F
```

### Register Range

```bash
aurora_fetch /dev/ttyUSB0 745-747
```

Output:
```
Heating Set Point (745): 68.0°F
Cooling Set Point (746): 73.0°F
Ambient Temperature (747): 73.0°F
```

### Multiple Ranges

Separate with spaces:

```bash
aurora_fetch /dev/ttyUSB0 745-747 813 1110-1111
```

### Predefined Sets

**known** - All recognized/named registers:
```bash
aurora_fetch /dev/ttyUSB0 known
```

**valid** - All registers in valid address ranges:
```bash
aurora_fetch /dev/ttyUSB0 valid
```

**all** - Every possible register (very slow, not recommended):
```bash
aurora_fetch /dev/ttyUSB0 all
```

## Output Formats

### Human-Readable (Default)

```bash
aurora_fetch /dev/ttyUSB0 745-746
```

Output:
```
Heating Set Point (745): 68.0°F
Cooling Set Point (746): 73.0°F
```

### YAML Format

```bash
aurora_fetch /dev/ttyUSB0 745-746 --yaml
```

Output:
```yaml
---
745: 680
746: 730
```

Values are raw register values (tenths of degrees for temperatures).

## Creating System Dumps

To capture your complete system state for debugging or sharing:

```bash
aurora_fetch /dev/ttyUSB0 valid --yaml > myheatpump.yml
```

This creates a YAML file with all readable registers. You can:
- Share with developers for troubleshooting
- Use with `aurora_mock` for testing
- Use as connection URI for other tools (simulation)
- Compare dumps over time to detect changes

## Connection Types

### Serial Port

```bash
aurora_fetch /dev/ttyUSB0 745
```

### Network Serial (TCP)

```bash
aurora_fetch tcp://192.168.1.50:2000/ 745
```

### Network Serial (RFC2217)

```bash
aurora_fetch rfc2217://192.168.1.50:2217/ 745
```

### MQTT Pass-Through

```bash
aurora_fetch mqtt://localhost/homie/aurora-XXXXX/$modbus 745
```

### YAML Simulation

```bash
aurora_fetch myheatpump.yml 745
```

See [Connections Guide](../connections/) for details on each connection type.

## Examples

### Check Current Temperatures

```bash
aurora_fetch /dev/ttyUSB0 567 747 1110-1111
```

Output:
```
Entering Air (567): 72.5°F
Ambient Temperature (747): 73.0°F
Leaving Water (1110): 95.3°F
Entering Water (1111): 87.8°F
```

### Check Power Usage

```bash
aurora_fetch /dev/ttyUSB0 1147 1149 1151 1153
```

Output:
```
Compressor Watts (1147): 2850
Blower Watts (1149): 425
Aux Watts (1151): 0
Total Watts (1153): 3275
```

### Check System Version

```bash
aurora_fetch /dev/ttyUSB0 2 88-109
```

Output:
```
ABC Program Version (2): 3.26
ABC Program (88-91): ABCVSPR
Model Number (92-104): 5 SERIES
Serial Number (105-109): 12345
```

### Dump for Sharing

```bash
# Create dump
aurora_fetch /dev/ttyUSB0 valid --yaml > my_7series.yml

# Compress for sharing
gzip my_7series.yml

# Result: my_7series.yml.gz
```

## Troubleshooting

### Timeout Errors

Some registers may timeout if they don't apply to your equipment:

```
Timeout reading register 813
```

This is normal. The tool will continue with remaining registers.

**To increase timeout:**

The default timeout is 15 seconds. To adjust, you would need to modify the source code in the tool itself.

### Permission Denied

```
Permission denied - /dev/ttyUSB0
```

**Solution:** Add your user to the dialout group:

```bash
sudo usermod -a -G dialout $USER
```

Log out and back in for changes to take effect.

### No Response

1. Verify connection:
   - Check cable is plugged in
   - Verify heat pump is powered on
   - Try different USB port
2. Check serial port name:
   ```bash
   ls /dev/ttyUSB*
   ```
3. Test with known register:
   ```bash
   aurora_fetch /dev/ttyUSB0 2  # ABC version, always present
   ```

### Unknown Registers

Some registers may show as unknown:

```
??? (742): 0 (0x0000)
```

These are valid registers but haven't been reverse-engineered yet. See [Reverse Engineering](../development/reverse-engineering.md) to help discover their meaning.

## Advanced Usage

### Scripting

Parse YAML output in scripts:

```bash
#!/bin/bash
# Get current heating setpoint
SETPOINT=$(aurora_fetch /dev/ttyUSB0 745 --yaml | grep '^745:' | awk '{print $2}')
echo "Current heating setpoint: $((SETPOINT / 10))°F"
```

### Monitoring Changes

Compare dumps over time:

```bash
# Initial dump
aurora_fetch /dev/ttyUSB0 valid --yaml > before.yml

# Make changes via AID tool or thermostat

# New dump
aurora_fetch /dev/ttyUSB0 valid --yaml > after.yml

# Compare
diff before.yml after.yml
```

### Cron Jobs

Monitor specific values:

```bash
# Add to crontab
*/5 * * * * aurora_fetch /dev/ttyUSB0 1153 --yaml >> /var/log/waterfurnace_power.log
```

## Performance Notes

- **Single register**: ~100ms
- **Small range (10 registers)**: ~200ms
- **known** (~200 registers): ~5-10 seconds
- **valid** (~1000 registers): ~30-60 seconds
- **all** (65536 registers): Hours (not recommended)

The ABC has a 100-register read limit per query, so large ranges are automatically split.

## Related Tools

- **[aurora_monitor](aurora_monitor.md)**: Watch live register changes
- **[aurora_mock](aurora_mock.md)**: Simulate ABC from dump file
- **[MQTT ModBus Pass-Through](../integration/mqtt.md#modbus-pass-through)**: Query via MQTT

## Next Steps

- [Register Reference](../development/registers.md) - Known register meanings
- [Reverse Engineering](../development/reverse-engineering.md) - Discover new registers
- [Connections Guide](../connections/) - Connection options
- [Troubleshooting](../troubleshooting.md) - Common issues
