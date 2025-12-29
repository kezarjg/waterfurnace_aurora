# Home Assistant Integration

The WaterFurnace Aurora gem integrates seamlessly with Home Assistant through MQTT autodiscovery using the Homie convention.

## Prerequisites

- [MQTT Bridge](mqtt.md) running and connected to your MQTT broker
- Home Assistant configured with MQTT integration
- MQTT discovery enabled in Home Assistant (default)

## Setup

### Step 1: Configure MQTT in Home Assistant

If you haven't already, add the MQTT integration in Home Assistant:

1. Go to **Settings** → **Devices & Services**
2. Click **Add Integration**
3. Search for **MQTT**
4. Enter your MQTT broker details (e.g., `raspberrypi.local` or `localhost`)

### Step 2: Enable Discovery

MQTT discovery is typically enabled by default. Verify in your `configuration.yaml`:

```yaml
mqtt:
  discovery: true
  discovery_prefix: homeassistant
```

### Step 3: Wait for Autodiscovery

Once the Aurora MQTT bridge is running, Home Assistant will automatically discover all entities. Within a few moments, you should see:

- **Climate entity**: Main thermostat control
- **Sensor entities**: Temperatures, humidity, power usage, etc.
- **Number entities**: Setpoint adjustments
- **Select entities**: Mode controls

All entities will appear under a device named "WaterFurnace" or similar.

## Available Entities

### Climate Control

- **climate.waterfurnace_zone_1**: Main thermostat
  - Set heating/cooling setpoints
  - Change HVAC mode (heat, cool, auto, off)
  - Fan mode (auto, continuous, intermittent)

Additional zones available if you have IntelliZone 2 (IZ2) system.

### Sensors

**Temperature Sensors:**
- Entering/leaving air temperature
- Entering/leaving water temperature
- Ambient temperature
- Domestic hot water temperature (if equipped)

**Humidity:**
- Relative humidity

**Power Monitoring** (if energy monitoring equipped):
- Total power usage
- Compressor power usage
- Blower power usage
- Loop pump power usage
- Aux heat power usage

**System Status:**
- Current mode
- Blower speed
- Compressor speed (if VS Drive)
- Water flow rate
- Fault status

### Controls

**Humidistat** (if equipped):
- Humidifier/dehumidifier mode
- Target humidity levels

**Domestic Hot Water** (if equipped):
- Enable/disable
- Temperature setpoint

**Pump** (if variable speed):
- Speed control (min/max/manual)

## Example Lovelace Card

Here's a comprehensive Lovelace card configuration showing all key WaterFurnace data:

```yaml
type: vertical-stack
cards:
  - type: custom:simple-thermostat
    entity: climate.waterfurnace_zone_1
    sensors:
      - entity: sensor.waterfurnace_humidistat_relative_humidity
        name: Humidity
      - entity: sensor.waterfurnace_heat_pump_total_power_usage
        name: Consumption
      - entity: sensor.waterfurnace_blower_current_speed
        name: Fan Speed
    control:
      hvac: true
      fan:
        auto:
          name: Auto
        continuous:
          name: Continuous
          icon: mdi:fan
        intermittent:
          name: Intermittent
          icon: mdi:fan
  - type: entities
    entities:
      - entities:
          - entity: sensor.waterfurnace_loop_pump_power_usage
            name: Pump
          - entity: sensor.waterfurnace_loop_pump_waterflow
            name: Water Flow
          - entity: sensor.waterfurnace_heat_pump_entering_water_temperature
            name: Entering Water Temp
          - entity: sensor.waterfurnace_heat_pump_leaving_water_temperature
            name: Leaving Water Temp
        entity: climate.waterfurnace_zone_1
        show_state: false
        name: Loop Details
        toggle: false
        type: custom:multiple-entity-row
      - entities:
          - entity: sensor.waterfurnace_heat_pump_entering_air_temperature
            name: Air Temp In
          - entity: sensor.waterfurnace_heat_pump_leaving_air_temperature
            name: Air Leaving Temp
        entity: climate.waterfurnace_zone_1
        show_state: false
        name: Air Sensors
        toggle: false
        type: custom:multiple-entity-row
      - head:
          entity: sensor.waterfurnace_heat_pump_total_power_usage
          name: Power Consumption
        items:
          - entity: sensor.waterfurnace_compressor_power_usage
            name: Compressor
          - entity: sensor.waterfurnace_blower_power_usage
            name: Fan
        type: custom:fold-entity-row
      - entity: sensor.waterfurnace_domestic_hot_water_generator_water_temperature
        name: Hot Water Heater Temp
```

**Note:** This example uses custom cards:
- [simple-thermostat](https://github.com/nervetattoo/simple-thermostat)
- [multiple-entity-row](https://github.com/benct/lovelace-multiple-entity-row)
- [fold-entity-row](https://github.com/thomasloven/lovelace-fold-entity-row)

Install via HACS or manually.

## Customizing Entities

### Renaming Entities

1. Go to **Settings** → **Devices & Services** → **Entities**
2. Search for "waterfurnace"
3. Click on any entity
4. Click the gear icon
5. Change the **Name** and **Entity ID**

### Hiding Unwanted Entities

If you don't want certain sensors cluttering your entity list:

1. Find the entity as above
2. Toggle **Enabled** to off
3. Entity will be hidden but data still available

### Organizing into Areas

Assign the WaterFurnace device to an area:

1. Go to **Settings** → **Devices & Services** → **Devices**
2. Find "WaterFurnace" device
3. Click on it
4. Set **Area** (e.g., "Mechanical Room", "Basement")

## Automations

### Example: Notify on Fault

```yaml
automation:
  - alias: "WaterFurnace Fault Alert"
    trigger:
      - platform: state
        entity_id: sensor.waterfurnace_heat_pump_fault_status
    condition:
      - condition: template
        value_template: "{{ trigger.to_state.state != 'OK' }}"
    action:
      - service: notify.mobile_app
        data:
          title: "Heat Pump Fault"
          message: "WaterFurnace fault: {{ states('sensor.waterfurnace_heat_pump_fault_status') }}"
```

### Example: Energy Tracking

```yaml
sensor:
  - platform: integration
    source: sensor.waterfurnace_heat_pump_total_power_usage
    name: waterfurnace_daily_energy
    unit_prefix: k
    round: 2
    method: left
```

Then add to Energy dashboard:
1. **Settings** → **Dashboards** → **Energy**
2. Add **Individual Devices**
3. Select `sensor.waterfurnace_daily_energy`

## Troubleshooting

### Entities Not Appearing

1. Check MQTT bridge is running: `sudo systemctl status aurora_mqtt_bridge`
2. Verify MQTT connection in Home Assistant (Settings → Devices & Services → MQTT)
3. Check MQTT topics with MQTT Explorer (should see `homeassistant/` topics)
4. Restart Home Assistant

### Entities Showing "Unavailable"

1. Check MQTT bridge logs: `sudo journalctl -u aurora_mqtt_bridge -f`
2. Verify heat pump is powered on and communicating
3. Check RS-485 connection
4. Restart MQTT bridge: `sudo systemctl restart aurora_mqtt_bridge`

### Wrong Values or Units

Some entities may need customization in `configuration.yaml`:

```yaml
homeassistant:
  customize:
    sensor.waterfurnace_heat_pump_entering_water_temperature:
      unit_of_measurement: "°F"
      device_class: temperature
```

## Advanced: Manual MQTT Subscribe

To manually inspect MQTT messages, use an MQTT client:

```bash
mosquitto_sub -h localhost -t 'homie/aurora-#' -v
```

Or use [MQTT Explorer](http://mqtt-explorer.com) for a GUI.

## Next Steps

- [MQTT Bridge Configuration](mqtt.md) - Advanced MQTT options
- [Web AID Tool](../tools/web_aid_tool.md) - Host web interface alongside MQTT bridge
- [ModBus Pass-Through](mqtt.md#modbus-pass-through) - Direct register access for debugging
- [Troubleshooting](../troubleshooting.md) - Common issues

## Related Links

- [Home Assistant MQTT Discovery](https://www.home-assistant.io/integrations/mqtt/#mqtt-discovery)
- [Homie Convention](https://homieiot.github.io/)
