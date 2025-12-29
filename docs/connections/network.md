# Network Serial Connections

Connect to your WaterFurnace heat pump over the network instead of local serial port.

## Overview

Network serial connections allow you to:
- Access heat pump from a different computer
- Share one serial connection among multiple clients
- Use Aurora tools on platforms without serial port support (Windows)
- Centralize RS-485 connection on a dedicated device

## Connection Types

### TCP Raw Serial

Direct TCP socket to serial port, no protocol overhead.

**URI Format:**
```
tcp://hostname:port/
```

**Example:**
```bash
aurora_fetch tcp://192.168.1.50:2000/ 745
```

### RFC2217 (Telnet Serial)

Telnet-based protocol that allows remote serial port configuration.

**URI Format:**
```
telnet://hostname:port/
rfc2217://hostname:port/
```

**Example:**
```bash
aurora_fetch rfc2217://192.168.1.50:2217/ 745
```

**Advantage:** Automatically configures baud rate, parity, etc.

## Setting Up Network Serial Server

### Option 1: ser2net (Recommended)

**ser2net** exposes local serial ports over TCP.

#### Installation

```bash
# Debian/Ubuntu
sudo apt install ser2net

# Fedora/RHEL
sudo dnf install ser2net
```

#### Configuration

Edit `/etc/ser2net.conf` (older versions) or `/etc/ser2net.yaml` (newer versions):

**Legacy format** (`/etc/ser2net.conf`):
```
2000:raw:0:/dev/ttyUSB0:19200 EVEN 8DATABITS 1STOPBIT
```

**YAML format** (`/etc/ser2net.yaml`):
```yaml
connection: &heatpump
  accepter: tcp,2000
  connector: serialdev,/dev/ttyUSB0,19200e81
  options:
    kickolduser: true
```

**Breakdown:**
- `2000`: TCP port to listen on
- `/dev/ttyUSB0`: Local serial device
- `19200`: Baud rate
- `e`: Even parity
- `8`: Data bits
- `1`: Stop bits

#### Enable and Start

```bash
sudo systemctl enable ser2net
sudo systemctl start ser2net
```

#### Verify

```bash
# Check status
sudo systemctl status ser2net

# Test connection
telnet localhost 2000
```

Should connect without errors. Press `Ctrl+]` then `quit` to exit.

#### Use from Remote Machine

```bash
aurora_fetch tcp://raspberrypi.local:2000/ 745
```

### Option 2: socat

**socat** can create network serial bridges.

```bash
socat TCP-LISTEN:2000,fork,reuseaddr FILE:/dev/ttyUSB0,b19200,parenb,cs8
```

**For permanent setup**, create systemd service:

```ini
[Unit]
Description=Serial to Network Bridge
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/socat TCP-LISTEN:2000,fork,reuseaddr FILE:/dev/ttyUSB0,b19200,parenb,cs8
Restart=always

[Install]
WantedBy=multi-user.target
```

### Option 3: RFC2217 Server

For RFC2217 support, use `ser2net` with telnet protocol:

**ser2net.conf:**
```
2217:telnet:0:/dev/ttyUSB0:19200 EVEN 8DATABITS 1STOPBIT banner
```

Or newer YAML:
```yaml
connection: &heatpump_rfc2217
  accepter: telnet(rfc2217),2217
  connector: serialdev,/dev/ttyUSB0,19200e81
```

**Usage:**
```bash
aurora_fetch rfc2217://raspberrypi.local:2217/ 745
```

## Client Configuration

### aurora_fetch

```bash
# TCP
aurora_fetch tcp://hostname:port/ <query>

# RFC2217
aurora_fetch rfc2217://hostname:port/ <query>
```

### aurora_mqtt_bridge

```bash
# TCP
aurora_mqtt_bridge tcp://hostname:port/ mqtt://localhost/

# RFC2217
aurora_mqtt_bridge rfc2217://hostname:port/ mqtt://localhost/
```

### web_aid_tool

```bash
# TCP
web_aid_tool tcp://hostname:port/

# RFC2217
web_aid_tool rfc2217://hostname:port/
```

## Use Cases

### Windows Client, Linux Server

**Server (Raspberry Pi):**
```bash
# Install ser2net on Pi
sudo apt install ser2net

# Configure /etc/ser2net.conf
2000:raw:0:/dev/ttyUSB0:19200 EVEN 8DATABITS 1STOPBIT

# Start service
sudo systemctl start ser2net
```

**Client (Windows):**
```bash
# Install Ruby and gem on Windows
aurora_fetch tcp://raspberrypi.local:2000/ 745
```

### Multiple Concurrent Clients

**Problem:** Can't share local serial port between multiple programs.

**Solution:** ser2net allows multiple sequential connections (one at a time):

```bash
# Client 1
aurora_fetch tcp://server:2000/ 745

# Client 2 (after client 1 disconnects)
web_aid_tool tcp://server:2000/
```

**For true concurrent access**, use MQTT bridge instead (see below).

### Centralized RS-485 Hub

Place Raspberry Pi near heat pump, access from anywhere:

```
[Heat Pump] ←(RS-485)→ [Raspberry Pi] ←(Ethernet)→ [Network] ←→ [Clients]
                            ↓
                        ser2net
```

### Long Distance Connection

USB RS-485 adapters work best < 50 feet. For longer distances:

1. Place computer/Pi near heat pump
2. Use ser2net to network-enable
3. Access from anywhere on network
4. For internet access, use VPN or secure tunnel

## MQTT Pass-Through

Alternative to network serial: use MQTT bridge as gateway.

**Setup:**

```bash
# Server: MQTT bridge owns serial port
aurora_mqtt_bridge /dev/ttyUSB0 mqtt://localhost/
```

**Client: Access via MQTT**

```bash
# Replace XXXXX with your heat pump serial number
aurora_fetch mqtt://mqtt-server/homie/aurora-XXXXX/$modbus 745
web_aid_tool mqtt://mqtt-server/homie/aurora-XXXXX/$modbus
```

**Advantages:**
- True concurrent access
- Built-in publish/subscribe
- Home automation integration
- Authentication via MQTT broker
- Encrypted via MQTTS

**Disadvantages:**
- Requires MQTT broker
- Slightly higher latency
- More complex setup

See [MQTT Integration](../integration/mqtt.md) for details.

## Security

### Network Serial Has No Security

**Risks:**
- No authentication - anyone can connect
- No encryption - traffic readable on network
- No authorization - full control of heat pump

**Mitigation:**

#### 1. Firewall

Only allow access from trusted IPs:

```bash
# Allow only local network
sudo ufw allow from 192.168.1.0/24 to any port 2000

# Or specific IP
sudo ufw allow from 192.168.1.100 to any port 2000
```

#### 2. VPN

Require VPN connection to access:
- WireGuard
- OpenVPN
- Tailscale

#### 3. SSH Tunnel

Encrypt traffic via SSH:

```bash
# On client machine
ssh -L 2000:localhost:2000 user@server

# Use localhost
aurora_fetch tcp://localhost:2000/ 745
```

#### 4. MQTT with Authentication

Use MQTT broker with username/password:

```bash
aurora_mqtt_bridge /dev/ttyUSB0 mqtt://user:pass@localhost/
```

Enable SSL/TLS:
```bash
aurora_mqtt_bridge /dev/ttyUSB0 mqtts://user:pass@broker/
```

## Troubleshooting

### Connection Refused

```
Connection refused - tcp://hostname:2000/
```

**Solutions:**

1. **Server not running:**
   ```bash
   sudo systemctl status ser2net
   ```

2. **Wrong port:**
   ```bash
   sudo netstat -tlnp | grep 2000
   ```

3. **Firewall blocking:**
   ```bash
   sudo ufw allow 2000
   ```

4. **Wrong hostname:**
   ```bash
   ping hostname
   ```

### Connection Timeout

```
Timeout connecting to tcp://hostname:2000/
```

**Solutions:**

1. **Network unreachable:**
   ```bash
   ping hostname
   traceroute hostname
   ```

2. **Firewall:**
   Test from server itself:
   ```bash
   telnet localhost 2000
   ```
   If works locally but not remotely, firewall issue.

3. **ser2net listening on localhost only:**

   Check ser2net config:
   ```
   # Wrong (localhost only)
   2000:raw:127.0.0.1:0:/dev/ttyUSB0:...

   # Right (all interfaces)
   2000:raw:0:/dev/ttyUSB0:...
   ```

### Data Corruption

**Symptoms:**
- Garbled output
- Random timeouts
- Wrong values

**Solutions:**

1. **Verify serial parameters:**
   Should be: 19200, Even, 8, 1

   Check ser2net config matches.

2. **Network issues:**
   - Packet loss
   - High latency
   - Buffer overruns

   Test network quality:
   ```bash
   ping hostname
   ```

3. **Use RFC2217:**
   Automatically configures parameters:
   ```bash
   aurora_fetch rfc2217://hostname:2217/ 745
   ```

### Multiple Connection Errors

```
Serial port busy
```

**Cause:** Another client is connected.

**Solutions:**

1. **Disconnect other clients**

2. **Use MQTT bridge** for concurrent access

3. **Configure ser2net to kick old user:**
   ```
   2000:raw:0:/dev/ttyUSB0:19200 EVEN 8DATABITS 1STOPBIT kickolduser
   ```

## Performance

### Latency

- **Local serial**: ~100ms
- **TCP (LAN)**: ~110ms
- **RFC2217 (LAN)**: ~120ms
- **MQTT (LAN)**: ~150ms
- **Internet/VPN**: +100-500ms (depends on distance)

### Throughput

Network adds minimal overhead. Bottleneck is still 19200 baud serial.

### Reliability

- **LAN**: Very reliable
- **WiFi**: Usually reliable, can have interference
- **Internet**: Depends on connection quality

## Best Practices

1. **Use RFC2217** when possible (automatic configuration)
2. **Firewall** server to restrict access
3. **Monitor logs** for unauthorized access
4. **Static IP or hostname** for server
5. **Systemd service** for automatic startup
6. **Test failover** - what happens if network fails?

## Next Steps

- [Serial Connection](serial.md) - Local serial setup
- [MQTT Integration](../integration/mqtt.md) - Alternative to network serial
- [Troubleshooting](../troubleshooting.md) - Common issues
- [Security Best Practices](../security.md) - Secure your deployment (if created)

## Related Links

- [ser2net documentation](https://linux.die.net/man/8/ser2net)
- [RFC2217 specification](https://tools.ietf.org/html/rfc2217)
- [socat examples](https://linux.die.net/man/1/socat)
