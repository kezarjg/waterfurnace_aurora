# aurora_monitor

A real-time monitoring tool that watches ModBus traffic between the ABC and AID Tool/AWL, displaying register changes as they happen.

## Purpose

`aurora_monitor` is essential for:
- **Reverse engineering**: Discover what registers change when you trigger actions
- **System debugging**: Watch real-time system behavior
- **Protocol analysis**: Understand communication patterns
- **Development**: Test new features and validate behavior

## Usage

```bash
aurora_monitor <connection> [options]
```

**Parameters:**
- `<connection>`: Serial port or network URI (see [Connections](../connections/))
- `[options]`: Filter and display options

## Basic Monitoring

### Default Output

Shows all traffic with full details:

```bash
aurora_monitor /dev/ttyUSB0
```

Output:
```
2021-08-27 14:05:15 +0000 ===== read
ABC Program Version (2): 3.26
Line Voltage (16): 240
Entering Air (567): 72.5°F
Heating Set Point (745): 68.0°F
Cooling Set Point (746): 73.0°F
Ambient Temperature (747): 73.0°F
Relative Humidity (741): 51%
Total Watts (1153): 3275
Compressor Watts (1147): 2850
Blower Watts (1149): 425
...
```

### Quiet Mode (Recommended)

Filter out noise and show only meaningful changes:

```bash
aurora_monitor /dev/ttyUSB0 -q
```

This enables:
- `-c`: Changes only (don't show unchanged values)
- `-u`: Hide unknown registers
- `-s`: Hide frequently updating sensors (power, temp)
- `-h`: Hide heartbeat/poll registers

Output:
```
2021-08-27 14:05:15 +0000 ===== read
Heating Set Point (745): 68.0°F → 70.0°F
Fan Mode (1220): auto → continuous
```

**This is the most useful mode for reverse engineering.**

## Command-Line Options

### -c, --changes-only

Only show registers that changed since last read:

```bash
aurora_monitor /dev/ttyUSB0 -c
```

### -u, --hide-unknown

Don't display unknown/unnamed registers:

```bash
aurora_monitor /dev/ttyUSB0 -u
```

### -s, --hide-sensors

Exclude frequently changing sensor values (temperatures, power, humidity):

```bash
aurora_monitor /dev/ttyUSB0 -s
```

### -h, --hide-heartbeat

Exclude registers that update every poll cycle (heartbeat counters):

```bash
aurora_monitor /dev/ttyUSB0 -h
```

### Combining Options

```bash
# Most useful: only show meaningful changes
aurora_monitor /dev/ttyUSB0 -c -u -s -h

# Shorthand (same as -q)
aurora_monitor /dev/ttyUSB0 -q
```

## Connection Setup

`aurora_monitor` requires **in-line** monitoring between the ABC and AID Tool/AWL.

### Hardware Setup

Use an [RJ45 breakout board](https://www.amazon.com/dp/B01GNOBDPM):

```
[Heat Pump ABC] ←→ [Breakout Board] ←→ [RS-485 Adapter] ←→ [Computer]
                          ↕
                    [AID Tool/AWL]
```

**Connections:**
1. Ethernet cable from heat pump AID port to breakout board
2. Cable from breakout board to your RS-485 adapter
3. Cable from breakout board to AID Tool or AWL

See [Hardware Guide](../../HARDWARE.md#in-line-monitoring-sniffing) for details.

### Why In-Line?

The ABC doesn't broadcast changes—it only responds to queries. By monitoring traffic between an AID Tool and ABC, you can:
- See what the AID Tool queries
- Observe the ABC's responses
- Correlate actions with register changes

## Reverse Engineering Workflow

### Step 1: Start Monitoring

```bash
aurora_monitor /dev/ttyUSB0 -q
```

### Step 2: Trigger Action

On the AID Tool or Symphony web interface, trigger the action you want to understand:
- Change a setpoint
- Switch fan mode
- Enable/disable a feature
- Adjust a speed setting

### Step 3: Observe Changes

Watch which registers change:

```
2021-08-27 14:05:15 +0000 ===== read
Heating Set Point (745): 68.0°F → 70.0°F
```

### Step 4: Document

Record your findings:
- Which register changed
- What action triggered it
- The before/after values
- Any patterns or relationships

### Step 5: Test Hypothesis

Use [aurora_fetch](aurora_fetch.md) to verify register purpose:

```bash
# Write to the register you suspect
aurora_mqtt_bridge /dev/ttyUSB0 mqtt://localhost/
mosquitto_pub -t 'homie/aurora-XXX/$modbus/745/set' -m '690'

# Verify change on thermostat display
```

## Example Sessions

### Discovering Blower Speed Control

```bash
$ aurora_monitor /dev/ttyUSB0 -q

# Change blower speed to "high" on AID tool...

2021-08-27 14:10:22 +0000 ===== read
ECM Speed (344): 5 → 9
Blower Only Speed (340): 3 → 5

# Conclusion: Register 340 controls manual blower speed
```

### Finding Humidity Settings

```bash
$ aurora_monitor /dev/ttyUSB0 -q

# Enable dehumidification mode...

2021-08-27 14:15:30 +0000 ===== read
??? (1221): 0 → 1
??? (1222): 0 → 45

# Test hypothesis: 1221 = humidifier enabled, 1222 = target %
```

### Tracking Mode Changes

```bash
$ aurora_monitor /dev/ttyUSB0 -q

# Switch from Auto to Heat mode...

2021-08-27 14:20:15 +0000 ===== read
Mode (1220): 3 → 1
Status (31): 0x08 → 0x01
System Outputs (30): 0x0000 → 0x0001

# Multiple registers involved in mode changes
```

## Output Format

### Normal Line

```
<timestamp> ===== read
<Register Name> (<number>): <value>
```

### Change Line (with -c)

```
<Register Name> (<number>): <old_value> → <new_value>
```

### Unknown Register

```
??? (<number>): <value> (0x<hex>)
```

### Write Operation

```
<timestamp> ===== write
<Register Name> (<number>): <value>
```

## Troubleshooting

### No Output

1. Verify in-line connection is correct
2. Trigger traffic by interacting with AID Tool
3. Check that both ABC and AID Tool are powered
4. Ensure RS-485 wiring is correct (A+/B-)

### Too Much Output

Use filters:
```bash
aurora_monitor /dev/ttyUSB0 -q  # Quietest
```

Or specific filters:
```bash
aurora_monitor /dev/ttyUSB0 -c -s  # Changes only, hide sensors
```

### Missing Expected Changes

Some registers only update when:
- System is actively running
- Certain modes are enabled
- Specific hardware is present

Try triggering actions while system is running.

### Permission Denied

```bash
sudo usermod -a -G dialout $USER
```

Log out and back in.

## Advanced Usage

### Save Session

```bash
aurora_monitor /dev/ttyUSB0 -q | tee monitor_session.log
```

### Filter Specific Registers

Use grep to watch specific registers:

```bash
aurora_monitor /dev/ttyUSB0 | grep "Heating Set Point"
```

### Compare Before/After

```bash
# Monitor during baseline
aurora_monitor /dev/ttyUSB0 -c > before.log

# Make change

# Monitor after change
aurora_monitor /dev/ttyUSB0 -c > after.log

# Compare
diff before.log after.log
```

## Performance Notes

- Monitor is passive (read-only)
- No impact on ABC communication
- Low CPU usage
- Can run for extended periods

## Related Tools

- **[aurora_fetch](aurora_fetch.md)**: Query specific registers
- **[aurora_mock](aurora_mock.md)**: Replay captured data
- **[Register Reference](../development/registers.md)**: Known register meanings
- **[Reverse Engineering Guide](../development/reverse-engineering.md)**: Methodology

## Next Steps

- [Reverse Engineering Guide](../development/reverse-engineering.md) - Discover new registers
- [Register Reference](../development/registers.md) - Document findings
- [Protocol Documentation](../development/protocol.md) - Understand ModBus extensions
- [Hardware Guide](../../HARDWARE.md) - Set up in-line monitoring

## Tips for Success

1. **Start with -q flag**: Reduces noise significantly
2. **One action at a time**: Isolate what causes each change
3. **Document everything**: Keep notes of what you discover
4. **Test hypotheses**: Use aurora_fetch to verify
5. **Share findings**: Contribute back to the project
6. **Be patient**: Some features involve multiple registers
