# Hardware Connection Guide

This guide covers the physical connections needed to communicate with your WaterFurnace heat pump's Aurora Base Control (ABC) unit via RS-485.

## Table of Contents

- [Safety Warnings](#safety-warnings)
- [Required Hardware](#required-hardware)
- [Cable Wiring](#cable-wiring)
- [Connection Points](#connection-points)
- [Advanced Setups](#advanced-setups)

## Safety Warnings

**⚠️ CRITICAL SAFETY INFORMATION ⚠️**

**THE AID TOOL PORT IS NOT ETHERNET**
- The "AID Tool Port" on the heat pump and Aurora Web Link uses an RJ-45 connector but is **NOT Ethernet**
- **NEVER connect a laptop, router, switch, or any Ethernet device to the AID Tool Port**
- This port carries **RS-485 communication signals AND 24 VAC power**
- Connecting Ethernet equipment **WILL damage** your laptop, the heat pump, or both

**DO NOT SHORT POWER PINS**
- Only connect the RS-485 signal pins (see wiring instructions below)
- **Never connect, short, or ground the 24 VAC power pins**
- Shorting power pins can blow the heat pump’s 3 A fuse or permanently damage the ABC board

**You have been warned. Proceed carefully and at your own risk.**

## Required Hardware

### RS-485 Adapter

You need an RS-485 to USB/Serial adapter. Options include:

- [USB RS-485 adapter](https://www.amazon.com/dp/B07B416CPK) (recommended)
- [Alternative USB RS-485 adapter](https://www.amazon.com/dp/B081MB6PN2)
- Raspberry Pi GPIO with proper isolation (advanced)

**NOT SUPPORTED:** Any adapter based on the MAX485 chip will not work.

### Cable

- CAT5/CAT5e/CAT6 ethernet cable
- RJ45 jack (if making custom cable)
- RJ45 crimp tool (if making custom cable)

## Cable Wiring

### Standard TIA-568-B Cable

The easiest approach is to use a standard TIA-568-B terminated cable and cut one end:

![Cable](doc/cable.jpg)

**Wiring Instructions:**

1. Ensure the jack end is wired for [TIA-568-B](https://upload.wikimedia.org/wikipedia/commons/6/60/RJ-45_TIA-568B_Left.png)
2. At the other end, remove jacket and strip wires
3. Twist together the following pairs:
   - **RS-485 A (+)**: White/Orange + White/Green (pins 1 & 3)
   - **RS-485 B (-)**: Orange + Blue (pins 2 & 4)

**Do not connect pins 5, 6, 7, or 8** - these carry 24VAC power.

### Connection Table

When using a TIA-568-B terminated cable with a USB RS-485 dongle:

| Dongle Terminal | RJ-45 Pin | Wire Color | RS-485 Signal |
|-----------------|-----------|------------|---------------|
| TXD+ (A+)       | 1 and 3   | white-orange and white-green | A+ |
| TXD- (B-)       | 2 and 4   | solid orange and solid blue | B- |
| RXD+            | None      | None       | None |
| RXD-            | None      | None       | None |
| GND             | None      | None       | None |

### Bus Connection Diagram

![Bus Connection](doc/connection_chart.png)

## Connection Points

### Option 1: Direct to Heat Pump

Connect the RJ45 jack directly to the AID Tool port on your heat pump:

![Connected to Heat Pump](doc/cable_in_heat_pump.jpg)

This is the simplest method and works if you don't have an Aurora Web Link (AWL).

### Option 2: Via Aurora Web Link (AWL)

If you want to keep your AWL functional:

1. Connect AWL to the AID port on the heat pump
2. Connect your cable to the AID Tool pass-through port on the AWL

![Connected to AWL](doc/cable_in_awl.jpg)

This allows both the AWL and your computer to communicate with the ABC.

### Option 3: Computer Connection

Connect the USB RS-485 adapter to your computer:

![Connected to Raspberry Pi](doc/cable_in_pi.jpg)

On Linux, the device will typically appear as `/dev/ttyUSB0` or similar.

## Advanced Setups

### In-Line Monitoring (Sniffing)

To eavesdrop on existing communication between an AID Tool/AWL and the ABC, you have two options:

#### RJ45 Breakout Board (Recommended)

Use an [RJ45 breakout board](https://www.amazon.com/dp/B01GNOBDPM):

1. Cable from heat pump to breakout board
2. Cable from breakout board to RS-485 dongle
3. Cable from breakout board to AWL/AID Tool

**Advantages:**
- Easy to reconfigure by swapping cables
- No permanent cable modification
- Can provide 24VAC power separately if needed

#### Custom Y-Cable

Create a cable with both ends intact and a tap in the middle (advanced).

### Simulating the ABC

If testing without a heat pump:

1. Use breakout board as above
2. Omit cable to heat pump
3. Provide 24VAC power to AID Tool via:
   - Separate cable to power pins on breakout board, OR
   - 24VAC power supply connected to C/R terminals

### Network Serial Ports

Instead of local USB connection, you can use network-connected serial devices. See [Network Connections](docs/connections/network.md) for details on:
- TCP raw serial ports
- RFC2217 telnet serial ports
- MQTT pass-through

### Direct Raspberry Pi GPIO

Advanced users can connect RS-485 directly to Raspberry Pi GPIO pins with proper isolation circuitry. This requires electrical engineering knowledge and is not recommended for beginners.

## Troubleshooting Hardware

### No Communication

1. Check that LED on RS-485 adapter blinks during communication attempts
2. Verify correct wiring (A+ and B- pairs)
3. Ensure no power pins are connected
4. Check that heat pump is powered on
5. Try different baud rates (should be 19200)

### Intermittent Communication

1. Check wire twist quality (twisted pairs reduce interference)
2. Ensure cable length is reasonable (< 50 feet for USB adapters)
3. Verify no damaged wires or loose connections
4. Check for electrical interference sources

### Adapter Not Recognized

1. On Linux: Check `dmesg` output after plugging in
2. Install necessary drivers for your RS-485 adapter
3. Verify USB cable is data-capable (not power-only)
4. Try different USB port

## Next Steps

- [Getting Started Guide](../../getting-started.md) - Quick software setup
- [Serial Connection Guide](serial.md) - Software configuration for serial ports
- [Network Connection Guide](network.md) - Using network serial ports
- [Troubleshooting](../troubleshooting.md) - Common issues and solutions
