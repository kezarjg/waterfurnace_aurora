# MQTT Bridge

The Aurora MQTT bridge (`aurora_mqtt_bridge`) publishes heat pump status to MQTT and accepts control commands, enabling integration with home automation systems.

## Overview

The bridge uses the [Homie convention](https://homieiot.github.io) for self-describing MQTT topics, making device discovery automatic in compatible systems like Home Assistant and OpenHAB.

**Key Features:**
- Automatic device discovery
- Real-time status updates
- Bidirectional control
- ModBus register pass-through for debugging
- Optional web AID tool hosting

## Prerequisites

- MQTT broker (e.g., [Mosquitto](https://mosquitto.org))
- RS-485 connection to heat pump (see [Hardware Guide](../connections/hardware.md))
- Ruby 2.5+ with waterfurnace_aurora gem installed

## Basic Usage

### Command Line

```bash
aurora_mqtt_bridge <serial_port> <mqtt_uri>
```

**Examples:**

```bash
# Local serial port, local MQTT broker
aurora_mqtt_bridge /dev/ttyUSB0 mqtt://localhost/

# Local serial port, remote MQTT broker
aurora_mqtt_bridge /dev/ttyUSB0 mqtt://192.168.1.100/

# Network serial port, MQTT with authentication
aurora_mqtt_bridge tcp://192.168.1.50:2000/ mqtt://user:pass@mqtt.example.com/

# MQTT over TLS
aurora_mqtt_bridge /dev/ttyUSB0 mqtts://mqtt.example.com/
```

### Connection URIs

**Serial Ports:**
- Direct: `/dev/ttyUSB0` (Linux), `/dev/tty.usbserial-*` (Mac)
- TCP: `tcp://hostname:port/`
- Telnet/RFC2217: `telnet://hostname:port/` or `rfc2217://hostname:port/`
- MQTT: `mqtt://broker/topic` (for pass-through to another bridge)
- YAML file: `path/to/dump.yml` (simulated ABC)

See [Connections Guide](../connections/) for details.

**MQTT URIs:**
- Basic: `mqtt://hostname/`
- With auth: `mqtt://username:password@hostname/`
- With port: `mqtt://hostname:1883/`
- TLS/SSL: `mqtts://hostname/`
- URI encoding: Special characters must be URI-encoded (e.g., `%40` for `@`)

**Note:** In systemd service files, `%` must be doubled (`%%`).

## Systemd Service

For automatic startup on Linux systems with systemd:

### Installation

```bash
sudo curl https://github.com/ccutrer/waterfurnace_aurora/raw/main/contrib/aurora_mqtt_bridge.service -L -o /etc/systemd/system/aurora_mqtt_bridge.service
sudo nano /etc/systemd/system/aurora_mqtt_bridge.service
```

### Configuration

Edit the service file to match your setup:

```ini
[Unit]
Description=WaterFurnace Aurora MQTT Bridge
After=network.target mosquitto.service

[Service]
Type=simple
User=pi
ExecStart=/usr/local/bin/aurora_mqtt_bridge /dev/ttyUSB0 mqtt://localhost/
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Customize:**
- `User=`: Your username
- `/dev/ttyUSB0`: Your serial port
- `mqtt://localhost/`: Your MQTT broker URI

**With authentication:**

```ini
ExecStart=/usr/local/bin/aurora_mqtt_bridge /dev/ttyUSB0 'mqtt://username:password@mqtt.example.com/'
```

Note the single quotes to prevent shell interpretation. Remember to URI-escape special characters and double `%` symbols.

### Enable and Start

```bash
sudo systemctl enable aurora_mqtt_bridge
sudo systemctl start aurora_mqtt_bridge
```

### Monitor Status

```bash
# Check status
sudo systemctl status aurora_mqtt_bridge

# View logs
sudo journalctl -u aurora_mqtt_bridge -f

# Restart service
sudo systemctl restart aurora_mqtt_bridge
```

## MQTT Topics

### Structure

```
homie/aurora-<serialno>/
├── $homie = "4.0.0"
├── $name = "Aurora"
├── $state = "ready"
├── $nodes = "zone1,compressor,blower,..."
│
├── zone1/
│   ├── $name = "Zone 1"
│   ├── $type = "thermostat"
│   ├── $properties = "heating-setpoint,cooling-setpoint,..."
│   ├── heating-setpoint = "68"
│   ├── heating-setpoint/$settable = "true"
│   ├── cooling-setpoint = "73"
│   └── ...
│
├── compressor/
│   ├── $name = "Compressor"
│   ├── $properties = "power,speed,..."
│   └── ...
│
└── $modbus/
    └── (pass-through for register access)
```

### Available Nodes

Depending on your equipment:
- `zone1`, `zone2`, ... - Thermostat zones
- `heatpump` - Main heat pump status
- `compressor` - Compressor (GenericCompressor or VSDrive)
- `blower` - Blower (PSC, ECM, or FiveSpeed)
- `pump` - Loop pump
- `dhw` - Domestic hot water (if equipped)
- `humidistat` - Humidifier/dehumidifier (if equipped)
- `auxheat` - Auxiliary electric heat

### Reading Values

Subscribe to all topics:
```bash
mosquitto_sub -h localhost -t 'homie/aurora-#' -v
```

### Writing Values

Writable properties have `$settable = "true"`. To set a value:

```bash
mosquitto_pub -h localhost -t 'homie/aurora-XXXXX/zone1/heating-setpoint/set' -m '70'
```

**Common writable properties:**
- `zone1/heating-setpoint/set` - Heating setpoint (°F)
- `zone1/cooling-setpoint/set` - Cooling setpoint (°F)
- `zone1/mode/set` - HVAC mode (off, heat, cool, auto, eheat)
- `zone1/fan-mode/set` - Fan mode (auto, continuous, intermittent)
- `dhw/enabled/set` - DHW on/off (true/false)
- `dhw/setpoint/set` - DHW temperature (100-140°F)

## ModBus Pass-Through

For debugging and advanced use, the bridge provides direct register access via the `$modbus` topic.

### Reading Registers

Publish a register query to `homie/aurora-<serialno>/$modbus`:

**Single register:**
```bash
mosquitto_pub -h localhost -t 'homie/aurora-XXXXX/$modbus' -m '813'
```

Response:
```
homie/aurora-XXXXX/$modbus/813 <= IZ2 Version (813): 2.06
```

**Register range:**
```bash
mosquitto_pub -h localhost -t 'homie/aurora-XXXXX/$modbus' -m '745-747'
```

Response:
```
homie/aurora-XXXXX/$modbus/745 <= Heating Set Point (745): 68.0°F
homie/aurora-XXXXX/$modbus/746 <= Cooling Set Point (746): 73.0°F
homie/aurora-XXXXX/$modbus/747 <= Ambient Temperature (747): 73.0°F
```

**Predefined sets:**
```bash
# All known/named registers
mosquitto_pub -h localhost -t 'homie/aurora-XXXXX/$modbus' -m 'known'

# All registers in valid ranges
mosquitto_pub -h localhost -t 'homie/aurora-XXXXX/$modbus' -m 'valid'

# All possible registers (slow!)
mosquitto_pub -h localhost -t 'homie/aurora-XXXXX/$modbus' -m 'all'
```

### Writing Registers

Publish value to `homie/aurora-<serialno>/$modbus/<register>/set`:

```bash
# Set blower-only speed to 3
mosquitto_pub -h localhost -t 'homie/aurora-XXXXX/$modbus/340/set' -m '3'
```

Response confirms:
```
homie/aurora-XXXXX/$modbus/340 <= Blower Only Speed (340): 3
```

**⚠️ Warning:** Direct register writes can damage your system if you write incorrect values. Use with caution and only if you know what you're doing.

## Web AID Tool Integration

You can host the [Web AID Tool](../tools/web_aid_tool.md) directly from the MQTT bridge:

```bash
aurora_mqtt_bridge /dev/ttyUSB0 mqtt://localhost/ --web-aid-tool=4567
```

This starts a web server on port 4567 serving the AID Tool interface.

**For external access** (from other devices on network):

```bash
APP_ENV=production aurora_mqtt_bridge /dev/ttyUSB0 mqtt://localhost/ --web-aid-tool=4567
```

**In systemd service file:**

```ini
[Service]
Environment=APP_ENV=production
ExecStart=/usr/local/bin/aurora_mqtt_bridge /dev/ttyUSB0 mqtt://localhost/ --web-aid-tool=4567
```

Access at: `http://raspberrypi.local:4567/`

## Configuration Options

The bridge reads configuration from command-line arguments. For full options:

```bash
aurora_mqtt_bridge --help
```

**Common options:**
- `--web-aid-tool=PORT` - Enable web interface on specified port
- Connection parameters inherited from URI format

## Troubleshooting

### Bridge Won't Start

```bash
# Check service status
sudo systemctl status aurora_mqtt_bridge

# View detailed logs
sudo journalctl -u aurora_mqtt_bridge -n 50
```

**Common issues:**
- Serial port permissions: Add user to `dialout` group
  ```bash
  sudo usermod -a -G dialout $USER
  ```
  Then log out and back in
- MQTT broker not running: `sudo systemctl start mosquitto`
- Wrong serial port: Check `ls /dev/ttyUSB*` or `dmesg | grep tty`

### No MQTT Messages

1. Verify MQTT broker is accessible:
   ```bash
   mosquitto_sub -h localhost -t '#' -v
   ```
2. Check bridge logs for connection errors
3. Verify MQTT URI is correct
4. Test MQTT authentication manually

### Data Not Updating

1. Check RS-485 connection to heat pump
2. Verify heat pump is powered on
3. Check for errors in logs
4. Try restarting the bridge

### Values Incorrect

Some registers may not apply to your equipment configuration. This is normal - the bridge queries all known registers but not all will be relevant.

## Advanced Configuration

### Custom Refresh Interval

The bridge automatically refreshes data periodically. To customize, you would need to modify the source code in `lib/aurora/abc_client.rb`.

### Multiple Bridges

You can run multiple bridges if you have multiple heat pumps, but each needs:
- Its own serial connection
- Unique MQTT topics (modify source to change base topic)

### MQTT Bridge Chaining

You can chain bridges using MQTT pass-through:

1. Primary bridge connected to heat pump publishes to MQTT
2. Secondary tool connects via MQTT URI:
   ```bash
   web_aid_tool mqtt://localhost/homie/aurora-XXXXX/$modbus
   ```

This allows multiple tools to access the same heat pump without multiple serial connections.

## Next Steps

- [Home Assistant Integration](home-assistant.md)
- [OpenHAB Integration](openhab.md)
- [Web AID Tool](../tools/web_aid_tool.md)
- [Development: Register Reference](../development/registers.md)
- [Troubleshooting](../troubleshooting.md)

## Related Links

- [Homie Convention](https://homieiot.github.io)
- [Mosquitto MQTT Broker](https://mosquitto.org)
- [MQTT Essentials](https://www.hivemq.com/mqtt-essentials/)
