# Troubleshooting Guide

Common issues and solutions for the WaterFurnace Aurora gem.

## Quick Diagnosis

**Problem category:**
- [Connection Issues](#connection-issues) - Can't connect to heat pump
- [Permission Issues](#permission-issues) - Access denied errors
- [MQTT Issues](#mqtt-issues) - MQTT bridge problems
- [Integration Issues](#integration-issues) - Home Assistant/OpenHAB
- [Data Issues](#data-issues) - Wrong or missing values
- [Performance Issues](#performance-issues) - Slow or timeout
- [Hardware Issues](#hardware-issues) - Physical connection problems

## Connection Issues

### No Response from Heat Pump

**Symptoms:**
```
Timeout reading register
No response from device
```

**Diagnosis:**

1. **Verify physical connection**
   ```bash
   # Check device exists
   ls /dev/ttyUSB*
   ```

2. **Test with simple query**
   ```bash
   # Register 2 should always respond (ABC version)
   aurora_fetch /dev/ttyUSB0 2
   ```

3. **Check heat pump power**
   - Verify heat pump is powered on
   - Check display is lit
   - Verify no tripped breakers

**Solutions:**

**A. Wrong device path**
```bash
# Find correct device
dmesg | grep tty | tail

# Try common paths
aurora_fetch /dev/ttyUSB0 2
aurora_fetch /dev/ttyUSB1 2
aurora_fetch /dev/ttyACM0 2
```

**B. Wiring issue**
- Check A+ and B- connections
- Verify cable continuity
- Ensure no shorts or damage
- See [Hardware Guide](../HARDWARE.md)

**C. Wrong baud/parity**

Should be auto-configured, but verify:
- 19200 baud
- Even parity
- 8 data bits
- 1 stop bit

**D. RS-485 adapter issue**
- Try different USB port
- Test adapter with loopback (short A+ to A+, B- to B-)
- Replace adapter if faulty

### Connection Works Sometimes

**Symptoms:**
- Works initially, then fails
- Intermittent timeouts
- Random disconnections

**Solutions:**

**A. USB power issue**
- Use powered USB hub
- Try different USB port
- Check USB cable quality

**B. Cable length**
- Keep USB cable < 6 feet
- Keep RS-485 cable < 50 feet for USB adapters
- Use quality twisted-pair cable (Cat5/6)

**C. Electrical interference**
- Move away from motors, transformers
- Avoid running parallel to power lines
- Use shielded cable if necessary

**D. Heat pump busy**
- ABC may be slow when system is active
- Increase timeout (source code modification required)
- Retry failed requests

### Network Connection Refused

**Symptoms:**
```
Connection refused - tcp://hostname:2000/
```

**Solutions:**

**A. Server not running**
```bash
# Check ser2net status
sudo systemctl status ser2net

# Start if stopped
sudo systemctl start ser2net
```

**B. Firewall blocking**
```bash
# Allow port
sudo ufw allow 2000

# Check if port is listening
sudo netstat -tlnp | grep 2000
```

**C. Wrong hostname/IP**
```bash
# Test connectivity
ping hostname

# Try IP address instead
aurora_fetch tcp://192.168.1.50:2000/ 2
```

## Permission Issues

### Permission Denied on Serial Port

**Symptoms:**
```
Permission denied - /dev/ttyUSB0
```

**Solution:**

**Add user to dialout group:**
```bash
sudo usermod -a -G dialout $USER
```

**Important:** Log out and back in for changes to take effect.

**Verify:**
```bash
groups $USER  # Should include 'dialout'
```

**Temporary fix for testing:**
```bash
sudo chmod 666 /dev/ttyUSB0  # Resets on reboot
```

### MQTT Permission Issues

**Symptoms:**
```
MQTT connection refused
Authentication failed
```

**Solutions:**

**A. Check MQTT broker running**
```bash
sudo systemctl status mosquitto
```

**B. Authentication required**

Update MQTT URI with credentials:
```bash
aurora_mqtt_bridge /dev/ttyUSB0 mqtt://username:password@hostname/
```

**C. URI escaping**

Special characters must be URI-encoded:
```
@ = %40
: = %3A (in password)
# = %23
```

**D. Certificate issues (MQTTS)**

Verify SSL/TLS certificate is valid:
```bash
openssl s_client -connect mqtt-broker:8883
```

## MQTT Issues

### MQTT Bridge Won't Start

**Check service status:**
```bash
sudo systemctl status aurora_mqtt_bridge
```

**View logs:**
```bash
sudo journalctl -u aurora_mqtt_bridge -n 50
```

**Common issues:**

**A. Wrong serial port in service file**

Edit `/etc/systemd/system/aurora_mqtt_bridge.service`:
```bash
sudo nano /etc/systemd/system/aurora_mqtt_bridge.service
```

Verify `ExecStart` line has correct device path.

**B. Wrong user**

Ensure `User=` in service file matches a real user with dialout group membership.

**C. MQTT broker not accessible**
```bash
# Test MQTT broker
mosquitto_sub -h localhost -t '#' -v
```

**D. Gem not installed**
```bash
# Verify installation
gem list | grep waterfurnace_aurora

# Reinstall if missing
sudo gem install waterfurnace_aurora
```

### No MQTT Messages Published

**Symptoms:**
- Bridge running, but no messages
- Empty topics in MQTT Explorer

**Diagnosis:**
```bash
# Watch all MQTT topics
mosquitto_sub -h localhost -t '#' -v

# Check bridge logs
sudo journalctl -u aurora_mqtt_bridge -f
```

**Solutions:**

**A. Wrong MQTT URI**

Verify MQTT broker address in service file.

**B. Heat pump not responding**

Bridge may be running but can't communicate with ABC:
- Check serial connection (see [Connection Issues](#connection-issues))
- Verify heat pump is powered on

**C. MQTT broker not receiving**

Test broker independently:
```bash
# Terminal 1: Subscribe
mosquitto_sub -h localhost -t 'test' -v

# Terminal 2: Publish
mosquitto_pub -h localhost -t 'test' -m 'hello'
```

## Integration Issues

### Home Assistant: Entities Not Appearing

**Solutions:**

**A. MQTT discovery not enabled**

Check `configuration.yaml`:
```yaml
mqtt:
  discovery: true
  discovery_prefix: homeassistant
```

Restart Home Assistant after changes.

**B. MQTT integration not configured**

1. Settings → Devices & Services
2. Add Integration → MQTT
3. Configure broker

**C. Wrong discovery prefix**

Bridge publishes to `homeassistant/` by default. Verify HA uses same prefix.

**D. Restart Home Assistant**
```bash
# Restart HA to refresh discovery
sudo systemctl restart home-assistant
```

### OpenHAB: Thing Not Discovered

**Solutions:**

**A. MQTT binding not installed**

1. Settings → Add-ons → Bindings
2. Search "MQTT"
3. Install MQTT Binding

**B. Broker thing not configured**

1. Settings → Things
2. Add Thing → MQTT → MQTT Broker
3. Configure connection

**C. Check inbox**

1. Settings → Things
2. Click inbox (bell icon)
3. Look for discovered Aurora device

**D. Clear cache**
```bash
# Stop OpenHAB
sudo systemctl stop openhab

# Clear cache
sudo openhab-cli clean-cache

# Start OpenHAB
sudo systemctl start openhab
```

## Data Issues

### Wrong Values Displayed

**Symptoms:**
- Temperatures seem wrong
- Negative values where shouldn't be
- Values don't match thermostat

**Solutions:**

**A. Unit conversion**

Some platforms may misinterpret units:
- Temperatures stored as tenths (680 = 68.0°F)
- Check if platform is doubling conversion

**B. Register doesn't apply**

Some registers only apply to specific equipment:
- VS Drive registers: Only if equipped
- IZ2 registers: Only multi-zone systems
- DHW registers: Only if domestic hot water present

Reading inapplicable registers may return 0 or garbage.

**C. Firmware version**

Older firmware may not support all registers. See [WaterFurnace Symphony docs](https://www.waterfurnace.com/literature/symphony/ig2001ew.pdf).

### Missing Data

**Symptoms:**
- Expected sensors not showing
- Entities unavailable
- Incomplete data

**Possible causes:**

**A. Equipment not present**

Check equipment configuration:
```bash
aurora_fetch /dev/ttyUSB0 88-109
```

Shows ABC version, model, serial number.

**B. Energy monitoring not equipped**

Power sensors (watts) require:
- Energy monitoring hardware
- AXB module (on some models)

**C. Pre-AWL firmware**

Older firmware has limited register availability.

**D. Feature not discovered yet**

May be undiscovered register. See [Reverse Engineering Guide](development/reverse-engineering.md).

### Values Not Updating

**Symptoms:**
- Stale data
- Changes not reflected
- Last update timestamp old

**Solutions:**

**A. Restart MQTT bridge**
```bash
sudo systemctl restart aurora_mqtt_bridge
```

**B. Check bridge logs**
```bash
sudo journalctl -u aurora_mqtt_bridge -f
```

Look for timeout errors or exceptions.

**C. Increase refresh rate**

Default refresh is periodic. May need source code modification for faster updates.

**D. Network latency**

Check network connectivity if using TCP/MQTT connections.

## Performance Issues

### Slow Queries

**Symptoms:**
- Commands take long time
- Frequent timeouts
- Poor responsiveness

**Solutions:**

**A. Reduce query scope**

Instead of:
```bash
aurora_fetch /dev/ttyUSB0 valid  # ~1000 registers, slow
```

Use:
```bash
aurora_fetch /dev/ttyUSB0 known  # ~200 registers, faster
```

**B. Network latency**

If using TCP/RFC2217:
- Use local serial instead
- Reduce network hops
- Check bandwidth

**C. System busy**

ABC is slower when heat pump is actively running. This is normal.

**D. Serial bottleneck**

19200 baud is the limit. Can't be increased.

### Frequent Timeouts

**Increase timeout (requires source modification):**

Edit `lib/aurora/abc_client.rb`:
```ruby
def initialize(port, timeout: 30)  # Increase from default 15
```

Or use shorter register ranges to stay under timeout.

## Hardware Issues

### RS-485 Adapter Not Recognized

**Symptoms:**
```
No such file or directory - /dev/ttyUSB0
```

**Solutions:**

**A. Check USB connection**
```bash
# Before plugging in
ls /dev/ttyUSB*

# Plug in adapter

# After plugging in (should see new device)
ls /dev/ttyUSB*

# Check kernel messages
dmesg | tail -20
```

**B. Driver issue**

Most USB-serial adapters work automatically on Linux. If not:
```bash
# Check loaded modules
lsmod | grep usbserial

# Load module if needed
sudo modprobe usbserial
```

**C. Faulty adapter**
- Try different USB port
- Try different USB cable
- Test adapter on different computer
- Replace if defective

### Cable Not Working

**Symptoms:**
- No communication despite correct device path
- Intermittent connection
- Communication works with loopback, fails with heat pump

**Diagnosis:**

**A. Test continuity**

Use multimeter to verify:
- Pin 1 to A+ terminal
- Pin 3 to A+ terminal
- Pin 2 to B- terminal
- Pin 4 to B- terminal
- No shorts between A and B
- No connection to other pins

**B. Verify twisted pairs**

Pins 1+3 should be twisted together (A+)
Pins 2+4 should be twisted together (B-)

**C. Check cable length**

USB adapters typically limited to < 50 feet RS-485 cable.

**D. Verify no power shorts**

**CRITICAL:** Pins 5,6,7,8 are 24VAC. Ensure:
- Not shorted to comm pins
- Not shorted to ground
- Not shorted together

### Heat Pump Won't Respond

**Symptoms:**
- Everything else works
- Adapter recognized
- Wiring verified
- Still no communication

**Checklist:**

1. **Heat pump powered on**
   - Display lit
   - No breakers tripped

2. **Correct port**
   - Using AID Tool port (not thermostat port)
   - On AWL: Use correct pass-through port

3. **ABC functional**
   - Test with real AID Tool if available
   - Verify ABC board not damaged

4. **Firmware compatibility**
   - Very old firmware may not support protocol
   - Check WaterFurnace for firmware updates

## Getting More Help

### Collect Diagnostic Information

**System info:**
```bash
# Ruby version
ruby --version

# Gem version
gem list | grep waterfurnace_aurora

# OS version
uname -a
lsb_release -a

# Serial devices
ls -l /dev/ttyUSB*
```

**Test basic connectivity:**
```bash
# Try reading ABC version
aurora_fetch /dev/ttyUSB0 2 2>&1 | tee test_output.txt
```

**Capture logs:**
```bash
# MQTT bridge logs
sudo journalctl -u aurora_mqtt_bridge -n 100 > mqtt_logs.txt

# System logs
dmesg | tail -50 > dmesg.txt
```

**Create system dump (if connecting works):**
```bash
aurora_fetch /dev/ttyUSB0 valid --yaml > my_system_dump.yml
```

### Report Issue

**On GitHub:**

1. Go to [Issues](https://github.com/ccutrer/waterfurnace_aurora/issues)
2. Search existing issues first
3. Create new issue with:
   - Problem description
   - Equipment details (model, firmware)
   - Diagnostic info (above)
   - What you've tried
   - Error messages (exact text)

**In Discussions:**

For questions rather than bugs: [GitHub Discussions](https://github.com/ccutrer/waterfurnace_aurora/discussions)

## Related Documentation

- [Hardware Guide](../HARDWARE.md) - Physical connection help
- [Serial Connection](connections/serial.md) - Serial port setup
- [Network Connection](connections/network.md) - TCP/RFC2217 setup
- [MQTT Bridge](integration/mqtt.md) - MQTT configuration
- [Home Assistant](integration/home-assistant.md) - HA troubleshooting
- [aurora_fetch](tools/aurora_fetch.md) - Query tool reference

---

**Still stuck?** Ask on [GitHub Discussions](https://github.com/ccutrer/waterfurnace_aurora/discussions)!
