# Getting Started on a Raspberry Pi

Don't care for the nitty gritty details? Here's the easy path! You'll need a
Raspberry Pi (tested on a Pi Zero W and a Pi 4), a
[USB RS-485 adapter](https://www.amazon.com/dp/B07B416CPK)
([alternative](https://www.amazon.com/dp/B081MB6PN2)),
and a network cable. Any adapter based on the MAX485 chip is _not_ supported.
Additional details can be found in the [Hardware Guide](HARDWARE.md) if
you want to deviate slightly from the simple path.

## Prerequisites

- Raspberry Pi (tested on Pi Zero W and Pi 4)
- USB RS-485 adapter (NOT MAX485-based)
- Ethernet cable (CAT5 or better)
- Basic terminal/SSH access to your Pi

## Step 1: Create Your Cable

Either cut the end of an existing patch cable, or take some CAT5 and crimp an
RJ45 jack on one end. Either way, ensure the end with a jack is wired for
[TIA-568-B](https://upload.wikimedia.org/wikipedia/commons/6/60/RJ-45_TIA-568B_Left.png).
Then remove some jacket at the other end, and strip and twist together
white/orange and white/green, and blue and orange. The first pair goes into the
A or + terminal, and the second pair goes into the B or - terminal on your
USB adapter:

![Cable](doc/cable.jpg)

**Important**: See the [Hardware Guide](HARDWARE.md) for detailed wiring information and safety warnings about power pins.

## Step 2: Connect to Your Heat Pump

Plug the jack into the AID tool port on your heat pump:

![Connected to Heat Pump](doc/cable_in_heat_pump.jpg)

Or, if you have an AWL, into the AID tool port of your AWL:

![Connected to AWL](doc/cable_in_awl.jpg)

Finally, plug the USB adapter into your Raspberry Pi:

![Connected to Raspberry Pi](doc/cable_in_pi.jpg)

## Step 3: Install Software

[Set up your Pi](https://projects.raspberrypi.org/en/projects/raspberry-pi-setting-up)
using the latest Raspberry Pi OS, connect it to the network, and then open a
terminal window (either SSH to it or launch the terminal app with a local
keyboard). Then install the software:

```sh
sudo apt install ruby ruby-dev
sudo gem install rake waterfurnace_aurora --no-doc
sudo apt install mosquitto
sudo curl https://github.com/ccutrer/waterfurnace_aurora/raw/main/contrib/aurora_mqtt_bridge.service -L -o /etc/systemd/system/aurora_mqtt_bridge.service
sudo nano /etc/systemd/system/aurora_mqtt_bridge.service # edit the service user to match your user
sudo systemctl enable aurora_mqtt_bridge
sudo systemctl start aurora_mqtt_bridge
```

Be sure to customize the `User=` line in the service file to match your username.

## Step 4: Verify It's Working

Congratulations, you should now be seeing data published to MQTT! You can
confirm this by using [MQTT Explorer](http://mqtt-explorer.com) and
connecting to raspberrypi.local:

![MQTT Explorer](doc/mqtt_explorer.png)

## Next Steps

- **Home Automation Integration**: See [Home Assistant](docs/integration/home-assistant.md) or [OpenHAB](docs/integration/openhab.md) guides
- **Configuration**: Learn about [MQTT Bridge options](docs/integration/mqtt.md)
- **Web Interface**: Set up the [Web AID Tool](docs/tools/web_aid_tool.md)
- **Troubleshooting**: Check the [Troubleshooting Guide](docs/troubleshooting.md) if you encounter issues

## Alternative Installation Methods

- **Docker**: See [docker/README.md](docker/README.md) for containerized deployment
- **Other Platforms**: See [Installation](README.md#installation) in main README for non-Raspberry Pi setups
- **Advanced Connections**: See the [Connections Guide](docs/connections/) for network serial ports, MQTT pass-through, and more
