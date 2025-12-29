# Serial Connection

Connect directly to your WaterFurnace heat pump via RS-485 serial port.

## Overview

Serial connection is the most common method, using an RS-485 to USB adapter connected directly to your computer.

## Hardware Requirements

- RS-485 to USB adapter (NOT MAX485-based)
- Ethernet cable with RJ45 jack
- Computer with USB port

See [Hardware Guide](../../HARDWARE.md) for wiring details.

## Device Paths

### Linux

RS-485 adapters typically appear as:
```
/dev/ttyUSB0
/dev/ttyUSB1
/dev/ttyACM0
```

**Find your device:**
```bash
# Before plugging in adapter
ls /dev/ttyUSB*

# Plug in adapter

# After plugging in
ls /dev/ttyUSB*

# Or check kernel messages
dmesg | grep tty
```

### macOS

Devices appear as:
```
/dev/tty.usbserial-*
/dev/cu.usbserial-*
```

**Find your device:**
```bash
ls /dev/tty.usbserial-*
```

Use the `/dev/cu.*` device for Aurora tools.

### Windows

Serial ports appear as `COM1`, `COM2`, etc.

**Note:** Windows support is limited. Consider using network serial port (ser2net) from a Linux device instead.

## Permissions (Linux)

### Add User to dialout Group

```bash
sudo usermod -a -G dialout $USER
```

**Important:** Log out and back in for group membership to take effect.

**Verify membership:**
```bash
groups $USER
```

Should show `dialout` in the list.

### Temporary Permission (Testing)

For one-time testing:
```bash
sudo chmod 666 /dev/ttyUSB0
```

**Warning:** Resets on reboot and less secure. Use group membership for permanent solution.

## Usage with Tools

### aurora_fetch

```bash
aurora_fetch /dev/ttyUSB0 745
```

### aurora_monitor

```bash
aurora_monitor /dev/ttyUSB0 -q
```

### aurora_mqtt_bridge

```bash
aurora_mqtt_bridge /dev/ttyUSB0 mqtt://localhost/
```

### web_aid_tool

```bash
web_aid_tool /dev/ttyUSB0
```

## Connection Parameters

The Aurora library automatically sets correct parameters:
- **Baud rate**: 19200
- **Data bits**: 8
- **Parity**: Even
- **Stop bits**: 1
- **Flow control**: None

No manual configuration needed.

## Troubleshooting

### Permission Denied

```
Permission denied - /dev/ttyUSB0
```

**Solution:**
```bash
sudo usermod -a -G dialout $USER
```

Log out and back in.

### Device Not Found

```
No such file or directory - /dev/ttyUSB0
```

**Solutions:**

1. **Check device exists:**
   ```bash
   ls /dev/ttyUSB*
   ```

2. **Adapter not recognized:**
   ```bash
   dmesg | grep usb
   ```
   Look for errors or driver issues.

3. **USB cable faulty:**
   Try different USB cable (must be data-capable).

4. **Different port:**
   Try `/dev/ttyACM0` or `/dev/ttyUSB1`.

### No Communication

```
Timeout reading register
```

**Checklist:**

1. **Wiring:**
   - Verify A+ and B- connections
   - Check for loose wires
   - Ensure no power pins connected

2. **Heat pump:**
   - Verify powered on
   - Check AID port is functional (test with real AID Tool if available)

3. **Adapter:**
   - Try different USB port
   - Verify adapter LED activity
   - Test adapter with loopback (short A+ to B+, A- to B-)

4. **Cable:**
   - Check for damage
   - Verify correct pinout
   - Test continuity

5. **Software:**
   - Test with simple command:
     ```bash
     aurora_fetch /dev/ttyUSB0 2  # ABC version, always present
     ```

### Intermittent Connection

**Symptoms:**
- Works sometimes, fails other times
- Random timeouts
- Corrupted data

**Solutions:**

1. **Cable quality:**
   - Use twisted pairs (cat5/6)
   - Keep cable length < 50 feet for USB adapters
   - Avoid running parallel to power lines

2. **USB power:**
   - Try powered USB hub
   - Avoid long USB extension cables
   - Check USB cable quality

3. **Electrical interference:**
   - Move away from motors, transformers
   - Use shielded cable if necessary
   - Check ground loops

4. **Adapter quality:**
   - Some cheap adapters are unreliable
   - Try recommended adapters from [Hardware Guide](../../HARDWARE.md)

### Multiple Devices

If you have multiple USB-serial adapters, they may swap device names on reboot.

**Solution:** Use udev rules to create persistent names.

**Create `/etc/udev/rules.d/99-waterfurnace.rules`:**

```bash
# Find adapter's serial number
udevadm info -a /dev/ttyUSB0 | grep serial

# Create rule (replace SERIAL_NUMBER with actual value)
SUBSYSTEM=="tty", ATTRS{serial}=="SERIAL_NUMBER", SYMLINK+="ttyHeatPump"
```

**Reload rules:**
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

**Use persistent name:**
```bash
aurora_mqtt_bridge /dev/ttyHeatPump mqtt://localhost/
```

## Performance

- **Latency**: ~100-200ms per query
- **Throughput**: Limited by 19200 baud rate
- **Reliability**: Very high with good hardware

## Security

Serial ports provide no authentication or encryption. Physical access to the port = full control.

**Mitigation:**
- Physical security of device with serial port
- Network isolation if exposing via network tools
- Authentication at application layer (MQTT, web proxy)

## Advanced

### Direct Raspberry Pi GPIO

Instead of USB adapter, connect RS-485 transceiver directly to Pi GPIO.

**Requires:**
- RS-485 transceiver IC (MAX3485 or similar)
- Proper voltage level shifting
- Electrical isolation (recommended)
- Kernel configuration for serial port

**Benefits:**
- No USB adapter needed
- More compact
- Lower cost

**Drawbacks:**
- Electrical engineering knowledge required
- Risk of damaging Pi
- More complex setup

**Not recommended for beginners.** Use USB adapter instead.

### Serial Port Sharing

You cannot have multiple programs access the same serial port simultaneously.

**Solutions:**

1. **MQTT bridge pass-through:**
   ```bash
   # Primary: MQTT bridge owns serial port
   aurora_mqtt_bridge /dev/ttyUSB0 mqtt://localhost/

   # Secondary: Access via MQTT
   web_aid_tool mqtt://localhost/homie/aurora-XXX/$modbus
   ```

2. **ser2net (network serial server):**
   ```bash
   # Install ser2net
   sudo apt install ser2net

   # Configure /etc/ser2net.conf
   2000:raw:0:/dev/ttyUSB0:19200 EVEN 8DATABITS 1STOPBIT

   # Restart
   sudo systemctl restart ser2net

   # Access via TCP
   aurora_fetch tcp://localhost:2000/ 745
   ```

See [Network Connections](network.md) for details.

## Next Steps

- [Network Connections](network.md) - Use serial over network
- [Hardware Guide](../../HARDWARE.md) - Wiring and safety
- [Troubleshooting](../troubleshooting.md) - Common issues
- [MQTT Bridge](../integration/mqtt.md) - Share serial port via MQTT
