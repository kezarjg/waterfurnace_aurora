# OpenHAB Integration

The WaterFurnace Aurora gem integrates with OpenHAB through the MQTT Binding using the Homie convention for automatic discovery.

## Prerequisites

- [MQTT Bridge](mqtt.md) running and connected to your MQTT broker
- OpenHAB installed and running
- MQTT Broker accessible (e.g., Mosquitto on same or different host)

## Setup

### Step 1: Install MQTT Binding

1. Open OpenHAB web interface
2. Go to **Settings** → **Add-ons** → **Bindings**
3. Search for "MQTT"
4. Install **MQTT Binding**

### Step 2: Add MQTT Broker Thing

1. Go to **Settings** → **Things**
2. Click the **+** button
3. Select **MQTT Binding**
4. Choose **MQTT Broker**
5. Configure connection:
   - **Host**: `raspberrypi.local` (or your MQTT broker address)
   - **Port**: `1883` (default)
   - **Username/Password**: If required by your broker
6. Save the thing

### Step 3: Discover Aurora Device

Once the MQTT bridge is running and the broker is connected:

1. Go to **Settings** → **Things**
2. Check your **Inbox** (bell icon)
3. You should see "Aurora" or "WaterFurnace" device discovered

![Aurora in OpenHAB Inbox](../../doc/openhab_inbox.png)

4. Click on the discovered device
5. Click **Add as Thing**

### Step 4: Link Channels to Items

After adding the thing, all channels will be automatically created:

![Aurora Channels](../../doc/openhab_channels.png)

Now link channels to items:

1. Click on the Aurora thing
2. Go to the **Channels** tab
3. For each channel you want to use:
   - Click the **Link** icon
   - Either select an existing item or **Create new item**
   - Follow the prompts to complete linking

## Available Channels

### Climate Control

- **Heating Setpoint**: Target temperature for heating mode
- **Cooling Setpoint**: Target temperature for cooling mode
- **Current Temperature**: Ambient/zone temperature
- **Current Mode**: Heat, Cool, Auto, Off, Emergency Heat
- **Fan Mode**: Auto, Continuous, Intermittent

### Temperature Sensors

- Entering Air Temperature
- Leaving Air Temperature
- Entering Water Temperature
- Leaving Water Temperature
- Domestic Hot Water Temperature (if equipped)

### Humidity

- Relative Humidity (read-only)
- Humidifier Target (if equipped)
- Dehumidifier Target (if equipped)
- Humidifier Mode (if equipped)

### Power Monitoring

If your system has energy monitoring:
- Total Power Usage
- Compressor Power Usage
- Blower Power Usage
- Loop Pump Power Usage
- Aux Heat Power Usage

### System Status

- Blower Speed
- Compressor Speed (if VS Drive equipped)
- Water Flow Rate (if flow meter equipped)
- Current Operation Mode
- Lockout Status
- Fault Status

## Example Items Configuration

If you prefer to manually configure items in `.items` files:

```java
// Climate Control
Number WF_Heating_Setpoint "Heating Setpoint [%.1f °F]" <temperature> {channel="mqtt:homie:broker:aurora:zone1#heating-setpoint"}
Number WF_Cooling_Setpoint "Cooling Setpoint [%.1f °F]" <temperature> {channel="mqtt:homie:broker:aurora:zone1#cooling-setpoint"}
Number WF_Current_Temp "Current Temperature [%.1f °F]" <temperature> {channel="mqtt:homie:broker:aurora:zone1#current-temperature"}
String WF_Mode "HVAC Mode" {channel="mqtt:homie:broker:aurora:zone1#mode"}
String WF_Fan_Mode "Fan Mode" {channel="mqtt:homie:broker:aurora:zone1#fan-mode"}

// Temperatures
Number WF_Entering_Air "Entering Air [%.1f °F]" <temperature> {channel="mqtt:homie:broker:aurora:heatpump#entering-air-temperature"}
Number WF_Leaving_Air "Leaving Air [%.1f °F]" <temperature> {channel="mqtt:homie:broker:aurora:heatpump#leaving-air-temperature"}
Number WF_Entering_Water "Entering Water [%.1f °F]" <temperature> {channel="mqtt:homie:broker:aurora:heatpump#entering-water-temperature"}
Number WF_Leaving_Water "Leaving Water [%.1f °F]" <temperature> {channel="mqtt:homie:broker:aurora:heatpump#leaving-water-temperature"}

// Power
Number WF_Total_Power "Total Power [%.0f W]" <energy> {channel="mqtt:homie:broker:aurora:heatpump#total-power"}
Number WF_Compressor_Power "Compressor Power [%.0f W]" <energy> {channel="mqtt:homie:broker:aurora:compressor#power"}

// Status
Number WF_Blower_Speed "Blower Speed" {channel="mqtt:homie:broker:aurora:blower#current-speed"}
Number WF_Water_Flow "Water Flow [%.1f GPM]" {channel="mqtt:homie:broker:aurora:pump#waterflow"}
```

**Note:** Channel names depend on your specific system configuration. Use the OpenHAB UI to discover exact channel IDs.

## Example Sitemap

```
sitemap waterfurnace label="WaterFurnace Heat Pump" {
    Frame label="Climate" {
        Setpoint item=WF_Heating_Setpoint minValue=55 maxValue=80 step=1
        Setpoint item=WF_Cooling_Setpoint minValue=60 maxValue=85 step=1
        Text item=WF_Current_Temp
        Selection item=WF_Mode mappings=[OFF="Off", HEAT="Heat", COOL="Cool", AUTO="Auto"]
        Selection item=WF_Fan_Mode mappings=[AUTO="Auto", CONTINUOUS="Continuous", INTERMITTENT="Intermittent"]
    }

    Frame label="Temperatures" {
        Text item=WF_Entering_Air
        Text item=WF_Leaving_Air
        Text item=WF_Entering_Water
        Text item=WF_Leaving_Water
    }

    Frame label="Power" {
        Text item=WF_Total_Power
        Text item=WF_Compressor_Power
    }

    Frame label="System Status" {
        Text item=WF_Blower_Speed
        Text item=WF_Water_Flow
    }
}
```

## Home Assistant Discovery

You may see duplicate things in your inbox for Home Assistant MQTT discovery topics. You can safely ignore these if you're only using OpenHAB:

1. Go to **Inbox**
2. Select Home Assistant discovered items
3. Click **Ignore**

## Rules Examples

### Example: Alert on High Power Usage

```java
rule "WaterFurnace High Power Alert"
when
    Item WF_Total_Power changed
then
    if (WF_Total_Power.state as Number > 5000) {
        sendNotification("you@example.com", "Heat pump power usage high: " + WF_Total_Power.state + " W")
    }
end
```

### Example: Track Daily Energy

```java
rule "WaterFurnace Daily Energy Reset"
when
    Time cron "0 0 0 * * ?"
then
    WF_Daily_Energy.postUpdate(0)
end

rule "WaterFurnace Energy Accumulation"
when
    Item WF_Total_Power changed
then
    val power = WF_Total_Power.state as Number
    val previous = WF_Daily_Energy.state as Number
    val increment = (power / 1000.0) / 60.0 // Wh per minute
    WF_Daily_Energy.postUpdate(previous + increment)
end
```

Add the accumulator item:

```java
Number WF_Daily_Energy "Daily Energy [%.2f kWh]" <energy>
```

## Troubleshooting

### Device Not Discovered

1. Verify MQTT broker thing is online
2. Check that aurora_mqtt_bridge service is running
3. Enable debug logging for MQTT binding:
   ```
   log:set DEBUG org.openhab.binding.mqtt
   ```
4. Check OpenHAB logs: **Settings** → **System** → **Logs**

### Channels Not Updating

1. Verify items are correctly linked to channels
2. Use MQTT Explorer to confirm data is being published
3. Check MQTT broker logs for connection issues
4. Restart OpenHAB: `sudo systemctl restart openhab`

### Incorrect Values

Some channel types may need adjustment. Edit the channel:

1. Go to **Thing** → **Channel**
2. Click channel name
3. Adjust **Number Pattern** or **String Format**

## Advanced: Manual Thing Configuration

For advanced users who prefer `.things` files:

```java
Bridge mqtt:broker:mosquitto "Mosquitto" [ host="raspberrypi.local", port=1883 ] {
    Thing homie aurora "WaterFurnace Aurora" [ deviceid="aurora-XXXXX", basetopic="homie" ] {
        // Channels will be auto-discovered from Homie convention
    }
}
```

## Next Steps

- [MQTT Bridge Configuration](mqtt.md) - Advanced MQTT options
- [ModBus Pass-Through](mqtt.md#modbus-pass-through) - Direct register access
- [Troubleshooting](../troubleshooting.md) - Common issues
- [OpenHAB MQTT Binding Docs](https://www.openhab.org/addons/bindings/mqtt/)

## Related Links

- [OpenHAB MQTT Binding](https://www.openhab.org/addons/bindings/mqtt/)
- [OpenHAB Homie Convention](https://www.openhab.org/addons/bindings/mqtt.homie/)
