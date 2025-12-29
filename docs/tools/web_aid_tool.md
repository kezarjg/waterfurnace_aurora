# Web AID Tool

A web-based reproduction of WaterFurnace's AID Tool interface, providing browser-based access to your heat pump.

## Purpose

The web AID tool provides:
- **Web interface**: Control heat pump from any device with a browser
- **AWL replacement**: Reproduces early Aurora Web Link functionality
- **Convenience**: No need for physical AID Tool
- **Multiple access**: Multiple users/devices can view simultaneously
- **Integration**: Can run alongside MQTT bridge

## Prerequisites

### Asset Files Required

For copyright reasons, the HTML/CSS/JavaScript assets from an actual AWL are not included. You must download them from your AWL before using the web AID tool.

**Download Script:**

```bash
curl https://github.com/ccutrer/waterfurnace_aurora/raw/main/contrib/grab_awl_assets.sh -L -o grab_awl_assets.sh
chmod +x grab_awl_assets.sh
./grab_awl_assets.sh
```

**For older AID Tools:**

```bash
./grab_awl_assets.sh 192.168.1.100
```

Replace with your AID Tool's IP address.

**Setup Mode (Newer AID Tools):**

Newer AID Tools require setup mode for access:

1. Hold down MODE button for 5 seconds
2. LED flashes green rapidly
3. Connect to WiFi network `AID-*` created by device
4. Run script:
   ```bash
   ./grab_awl_assets.sh
   ```
5. Assets downloaded to `html/` directory

## Basic Usage

### Standalone Mode

Run web AID tool directly connected to heat pump:

```bash
web_aid_tool /dev/ttyUSB0
```

Access at: `http://localhost:4567/`

### Production Mode (External Access)

Allow access from other devices on network:

```bash
APP_ENV=production web_aid_tool /dev/ttyUSB0
```

Access from other devices: `http://raspberrypi.local:4567/`

### Custom Port

```bash
web_aid_tool /dev/ttyUSB0 -p 8080
```

Access at: `http://localhost:8080/`

## Connection Types

### Serial Port

```bash
web_aid_tool /dev/ttyUSB0
```

### Network Serial (TCP)

```bash
web_aid_tool tcp://192.168.1.50:2000/
```

### Network Serial (RFC2217)

```bash
web_aid_tool rfc2217://192.168.1.50:2217/
```

### MQTT Pass-Through

Run alongside MQTT bridge without additional serial connection:

```bash
# Terminal 1: MQTT bridge
aurora_mqtt_bridge /dev/ttyUSB0 mqtt://localhost/

# Terminal 2: Web AID tool via MQTT
web_aid_tool mqtt://localhost/homie/aurora-XXXXX/$modbus
```

Replace `XXXXX` with your heat pump serial number.

### Mock ABC (Offline Testing)

```bash
# Terminal 1: Mock ABC
aurora_mock my_system.yml tcp://localhost:2000

# Terminal 2: Web AID tool
web_aid_tool tcp://localhost:2000
```

See [aurora_mock](aurora_mock.md) for details.

## Integration with MQTT Bridge

You can host the web AID tool directly from the MQTT bridge:

```bash
aurora_mqtt_bridge /dev/ttyUSB0 mqtt://localhost/ --web-aid-tool=4567
```

**With external access:**

```bash
APP_ENV=production aurora_mqtt_bridge /dev/ttyUSB0 mqtt://localhost/ --web-aid-tool=4567
```

**In systemd service:**

```ini
[Service]
Environment=APP_ENV=production
ExecStart=/usr/local/bin/aurora_mqtt_bridge /dev/ttyUSB0 mqtt://localhost/ --web-aid-tool=4567
```

This provides both MQTT integration and web interface from a single process.

## Features

### Status Monitoring

- Current temperatures (air, water)
- Current mode and fan status
- Setpoints (heating, cooling, DHW)
- Power usage (if equipped)
- System status and faults

### Control

- Adjust heating/cooling setpoints
- Change HVAC mode (heat, cool, auto, off)
- Fan mode control (auto, continuous, intermittent)
- DHW enable/disable and setpoint (if equipped)
- Blower speed (manual mode)
- Humidity settings (if equipped)

### Advanced

- Raw register access
- Fault history
- System configuration viewing
- Manual operation mode (diagnostic)

## Interface Sections

### Home Screen

- Current status overview
- Quick setpoint adjustment
- Mode indicators
- Temperature displays

### Settings

- Detailed setpoint configuration
- Fan mode selection
- Advanced options

### Diagnostics

- System sensors
- Power monitoring
- Fault history
- Register viewer

### Register Access

Direct register query and write:

```
Query: 745-747
Results:
  745: 680 (Heating Set Point: 68.0°F)
  746: 730 (Cooling Set Point: 73.0°F)
  747: 730 (Ambient Temperature: 73.0°F)
```

## Security Considerations

### No Built-in Authentication

The web AID tool has **no authentication** by default. Anyone who can access the web server can control your heat pump.

**Mitigation strategies:**

1. **Firewall**: Only allow access from trusted IPs
2. **VPN**: Require VPN connection to access
3. **Reverse proxy**: Use nginx/Apache with HTTP auth
4. **Network isolation**: Keep on isolated network

### Example: Nginx with Authentication

```nginx
server {
    listen 80;
    server_name heatpump.local;

    auth_basic "Heat Pump Access";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        proxy_pass http://localhost:4567;
    }
}
```

Create password file:
```bash
sudo htpasswd -c /etc/nginx/.htpasswd admin
```

### HTTPS

For encrypted access, use reverse proxy with SSL:

```nginx
server {
    listen 443 ssl;
    server_name heatpump.local;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:4567;
    }
}
```

## Troubleshooting

### Assets Not Found

**Error:** `404 Not Found` for CSS/JS files

**Solution:** Run asset download script:
```bash
curl https://github.com/ccutrer/waterfurnace_aurora/raw/main/contrib/grab_awl_assets.sh -L -o grab_awl_assets.sh
./grab_awl_assets.sh
```

Verify `html/` directory exists with files.

### Can't Access from Other Devices

**Problem:** Works on `localhost` but not from other devices

**Solution:** Use production mode:
```bash
APP_ENV=production web_aid_tool /dev/ttyUSB0
```

**Check firewall:**
```bash
sudo ufw allow 4567
```

### Port Already in Use

**Error:** `Address already in use`

**Solution:** Use different port or kill existing process:
```bash
lsof -i :4567
kill <PID>

# Or use different port
web_aid_tool /dev/ttyUSB0 -p 8080
```

### Connection Timeout

1. Verify heat pump connection
2. Check serial port permissions
3. Test with aurora_fetch first:
   ```bash
   aurora_fetch /dev/ttyUSB0 2
   ```
4. Check web server logs

### Interface Not Responsive

- Check browser console for JavaScript errors
- Verify assets loaded correctly
- Try different browser
- Clear browser cache

## Performance

### Concurrent Users

The web AID tool uses a mutex to prevent simultaneous ModBus access. Multiple users can view, but only one can control at a time.

**Symptoms of contention:**
- Slow response
- Timeout errors
- Stale data

**Solutions:**
- Limit concurrent users
- Use MQTT bridge for read-only monitoring
- Increase timeout values (source code modification)

### Resource Usage

- **Memory**: ~50MB Ruby process
- **CPU**: Minimal when idle, spikes during queries
- **Network**: Low bandwidth (small JSON responses)

Suitable for Raspberry Pi and similar devices.

## Advanced Usage

### Reverse Proxy

Use nginx for production deployment:

```nginx
upstream heatpump {
    server localhost:4567;
}

server {
    listen 80;
    server_name heatpump.example.com;

    location / {
        proxy_pass http://heatpump;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Custom Assets

Modify `html/` directory to customize interface:
- Edit CSS for styling changes
- Modify JavaScript for behavior changes
- Add custom pages or features

**Note:** Changes may be overwritten if you re-run asset download script.

### Monitoring Output

Enable monitoring output while serving web interface:

This requires source code modification. By default, only web interface is available.

## Related Tools

- **[aurora_mqtt_bridge](../integration/mqtt.md)**: Alternative control via MQTT
- **[aurora_fetch](aurora_fetch.md)**: Command-line register access
- **[aurora_mock](aurora_mock.md)**: Offline testing

## Next Steps

- [MQTT Bridge](../integration/mqtt.md) - Integrate with home automation
- [Home Assistant](../integration/home-assistant.md) - Modern web interface alternative
- [Troubleshooting](../troubleshooting.md) - Common issues
- [Security Best Practices](../security.md) - Secure your deployment (if created)

## Comparison: Web AID Tool vs MQTT Bridge

| Feature | Web AID Tool | MQTT Bridge |
|---------|--------------|-------------|
| **Interface** | Web browser | Home automation |
| **Authentication** | None (add via proxy) | MQTT broker auth |
| **Multiple users** | Yes (mutex limited) | Yes (concurrent) |
| **Real-time updates** | Poll-based | Push-based |
| **Mobile friendly** | Basic | Platform dependent |
| **Automation** | Manual only | Full automation |
| **Setup complexity** | Asset download required | Simple |

**Recommendation:** Use MQTT bridge for integration and automation, web AID tool for occasional manual control or when MQTT isn't available.
