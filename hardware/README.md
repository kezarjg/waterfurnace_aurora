# Hardware Designs

This directory contains CAD files for 3D-printable enclosures and hardware accessories for the WaterFurnace Aurora project.

## RS-485 Adapter Enclosure

**File:** `rs485_enclosure.scad`

A parametric enclosure designed to house a USB RS-485 adapter for connecting to your WaterFurnace heat pump. The file also includes detailed reference models of all components needed for a complete Aurora interface system.

**What's Included:**
- Complete enclosure design (base + lid) for RS-485 adapter
- Raspberry Pi Zero W Ver 1.1 reference model with exact dimensions
- USB to RS485 adapter reference model with platform/clip mounting
- 24VAC to 5VDC power adapter reference model
- Mounting post/platform generators for all components
- Keepout zone visualization for proper clearances
- Multi-component system layout templates

### Features

- Houses all three components in spacious 25cm × 15cm × 5cm enclosure
- **Raspberry Pi Zero W reference model** with accurate dimensions and keepout zones
- **USB to RS485 adapter reference model** with platform/clip mounting
- **24VAC to 5VDC power adapter reference model** with mounting posts
- Single RJ45 cable entry (14.6mm) for both RS-485 signals and 24VAC power
- Wall-mounting holes (M3 screws)
- Removable lid with M2.5 screws
- Ventilation slots for heat dissipation
- Labeled with "RS-485" and "WaterFurnace Aurora"
- Parametric design - easily customizable

### Reference Models

The SCAD file includes detailed models of all components needed for a complete Aurora interface system:

#### 1. Raspberry Pi Zero W Reference Model

Detailed model of the Raspberry Pi Zero W Ver 1.1 with:

**Accurate Dimensions:**
- PCB: 65mm × 30mm × 1.6mm
- Total height with components: 5mm
- 4× M2.5 mounting holes at 3.5mm from edges (2.75mm ±0.05mm diameter)

**Connector Locations:**
- **SD Card Slot**: Left edge, 16.9mm from bottom (requires 20mm clearance for removal)
- **Micro USB (RS-485)**: Bottom edge, 41.4mm from left
- **Micro USB (Power)**: Bottom edge, 54mm from left
- **Mini HDMI**: Right edge
- **GPIO Header**: Top edge (40-pin, 2×20)

**Keepout Zones:**
- Red zone: SD card removal clearance (20mm to left)
- Blue zones: USB and HDMI connector access
- Transparent overlays show required clearances

**Visual Layout:**
```
Top View (looking down):
    ┌─────────────────────────────── 65mm ───────────────────────────────┐
    │                                                                     │
    │  ○ Hole                                        GPIO Header          │ 30mm
    │  (3.5,26.5)              [██████████████████████████]  Hole ○      │
    │                                                         (61.5,26.5) │
SD  ╞══╡                                                                  ├─ HDMI
Card│                                                                     │
Slot│                                                                     │
    │  ○ Hole                                                  Hole ○    │
    │  (3.5,3.5)                                              (61.5,3.5) │
    │            USB         USB                                          │
    │           (41.4)      (54.0)                                        │
    └────────────┴───────────┴───────────────────────────────────────────┘
                 ↑           ↑
              RS-485      Power
```

**Usage:**
```openscad
// View the Pi model with keepout zones
raspberry_pi_zero_w(show_keepouts=true);

// Generate mounting posts for your enclosure
pi_zero_mounting_posts(post_height=3, post_dia=5.5, hole_dia=2.2);

// Use in your own enclosure design
translate([wall + 5, wall + 10, base_thickness]) {
    pi_zero_mounting_posts(post_height=3);
    translate([0, 0, 3])
        raspberry_pi_zero_w(show_keepouts=false);  // Hide keepouts in final design
}
```

#### 2. USB to RS485 Adapter Reference Model

Detailed model of a typical USB-RS485 converter dongle:

**Accurate Dimensions:**
- Main body: 53mm × 23.5mm × 14.3mm (L × W × H)
- USB-A connector (left): adds 12.7mm length, 11.8mm wide
- RS485 terminal (right): 9mm × 12.2mm × 11.4mm
- Total length with connectors: ~75mm

**Connector Locations:**
- **USB-A Connector**: Left side, centered (connects to Raspberry Pi)
- **RS485 Terminal**: Right side, centered (connects to heat pump)
- Status LED: Top center of main body

**Keepout Zones:**
- Cyan zone: USB cable clearance (25mm to left)
- Magenta zone: RS485 wire clearance (20mm to right)
- Yellow zone: Top LED visibility clearance (5mm above)

**Visual Layout:**
```
Side View (with connectors):
    USB-A          Main Body (53mm)        RS485
    Connector                              Terminal
    ┌────┐    ┌─────────────────────────┐  ┌──┐
    │    │────│                         │──│  │
    │    │    │  [USB-RS485 Adapter]   │  │  │
    │    │────│          ●LED           │──│  │
    └────┘    └─────────────────────────┘  └──┘
    12.7mm              53mm                9mm

    Total length: ~75mm
    Width: 23.5mm
    Height: 14.3mm (body), 11.4mm (RS485 terminal)
```

**Usage:**
```openscad
// View the USB-RS485 adapter model with keepout zones
usb_rs485_adapter(show_keepouts=true);

// Generate platform with clips to hold the adapter
usb_rs485_platform(platform_height=2, with_clips=true);

// Use in your enclosure design with platform
translate([wall + 5, wall + 10, base_thickness]) {
    usb_rs485_platform(platform_height=2, with_clips=true);
    translate([0, 0, 2])
        usb_rs485_adapter(show_keepouts=false);
}
```

**Note:** Most USB-RS485 adapters don't have mounting holes, so the design includes a platform with optional side clips to secure the adapter in place.

#### 3. 24VAC to 5VDC Power Adapter Reference Model

Detailed model of a typical AC-DC power converter board:

**Accurate Dimensions:**
- Board: 49mm × 26mm × 22mm (L × W × H)
- 4× M3 mounting holes at 2.5mm from edges (3mm diameter)

**Connector Locations:**
- **AC Input**: Left edge, centered (10mm wide connector)
- **DC Output**: Right edge, centered (10mm wide connector)
- Wire clearance required: 15mm on each side

**Keepout Zones:**
- Orange zone: AC input wire clearance (15mm to left)
- Purple zone: DC output wire clearance (15mm to right)
- Yellow zone: Top heat dissipation clearance (10mm above)

**Visual Layout:**
```
Top View (looking down):
    ┌──────────────── 49mm ────────────────┐
    │                                       │
AC  │  ○ Hole                    Hole ○    │  DC
In  │  (2.5,23.5)               (46.5,23.5)│  Out
══╡ │                                       │ ╞══
10mm│          [Power Module]               │ 10mm
    │                                       │ 26mm
    │  ○ Hole                    Hole ○    │
    │  (2.5,2.5)                (46.5,2.5) │
    └───────────────────────────────────────┘

Side View:
    ┌─────────────────┐
    │                 │ 22mm
    ├─────────────────┤ height
    └─────────────────┘
```

**Usage:**
```openscad
// View the power adapter model with keepout zones
power_adapter_24vac_5vdc(show_keepouts=true);

// Generate mounting posts for your enclosure
power_adapter_mounting_posts(post_height=3, post_dia=6, hole_dia=2.5);

// Use in your enclosure design
translate([wall + 5, wall + 10, base_thickness]) {
    power_adapter_mounting_posts(post_height=3);
    translate([0, 0, 3])
        power_adapter_24vac_5vdc(show_keepouts=false);
}
```

#### 4. Complete System Layout

For designing an integrated enclosure that houses all components, the default enclosure is 250mm × 150mm × 50mm (25cm × 15cm × 5cm), providing ample room for all three components with excellent airflow and access:

```openscad
// OPTION 10: View complete system with all three components
// Layout optimized for 25cm x 15cm enclosure
translate([0, 0, 0]) {
    // USB-RS485 adapter - front left
    translate([30, 30, 0]) {
        usb_rs485_platform(platform_height=2, with_clips=false);
        translate([0, 0, 2])
            usb_rs485_adapter(show_keepouts=false);
    }

    // Power adapter - back left
    translate([30, 90, 0]) {
        power_adapter_mounting_posts(post_height=3);
        translate([0, 0, 3])
            power_adapter_24vac_5vdc(show_keepouts=false);
    }

    // Pi Zero - right side, centered
    translate([140, 60, 0]) {
        pi_zero_mounting_posts(post_height=3);
        translate([0, 0, 3])
            raspberry_pi_zero_w(show_keepouts=false);
    }
}
```

This layout provides:
- **USB-RS485 adapter** in front left (receives RS-485 from RJ45 cable, USB cable routes internally to Pi)
- **Power adapter** in back left (24VAC tapped from RJ45 cable, DC output routes to Pi)
- **Raspberry Pi Zero W** on right side (good access to SD card and USB ports, receives power and data)
- Single RJ45 cable entry on left wall (14.6mm gland, centered) carrying both RS-485 + 24VAC - no separate power cable needed
- Generous spacing between components for heat dissipation and cable routing
- Easy access to all components for assembly and maintenance

The enclosure dimensions can be adjusted by editing the parameters at the top of the `.scad` file:
```openscad
internal_width = 250;     // Width (X) - 25 cm long
internal_depth = 150;     // Depth (Y) - 15 cm wide
internal_height = 50;     // Height (Z) - 5 cm deep
```

### Visualizing the Reference Models

Before designing or printing, you can view any of the reference models to understand dimensions and clearances:

1. **Open the file in OpenSCAD:**
   ```bash
   openscad rs485_enclosure.scad
   ```

2. **Choose which model to view** by commenting/uncommenting in the rendering section:
   ```openscad
   // Comment out OPTION 1 (default enclosure)
   //enclosure_base();
   //translate([outer_width + 10, 0, lid_thickness])
   //    rotate([180, 0, 0])
   //    enclosure_lid();

   // Uncomment OPTION 3 to view the Raspberry Pi Zero W
   raspberry_pi_zero_w(show_keepouts=true);

   // OR uncomment OPTION 5 to view the power adapter
   //power_adapter_24vac_5vdc(show_keepouts=true);

   // OR uncomment OPTION 8 to view the USB-RS485 adapter
   //usb_rs485_adapter(show_keepouts=true);

   // OR uncomment OPTION 10 to view all three components together
   //[see OPTION 10 code in the file]
   ```

3. **Press F5** to preview. Color coding:

   **Raspberry Pi Zero W:**
   - Green: PCB and components
   - Silver: Connectors (USB, HDMI, SD card)
   - Black: GPIO header
   - Red: SD card removal clearance zone
   - Blue: USB/HDMI connector access zones

   **Power Adapter:**
   - Blue: Power module body
   - Green: AC input connector
   - Red: DC output connector
   - Orange: AC wire clearance zone
   - Purple: DC wire clearance zone
   - Yellow: Top heat dissipation clearance

   **USB-RS485 Adapter:**
   - Dark green: Main adapter body
   - Silver: USB-A connector (left)
   - Green: RS485 terminal block (right)
   - Red: Status LED indicator
   - Cyan: USB cable clearance zone
   - Magenta: RS485 wire clearance zone
   - Yellow: LED visibility clearance

4. **Use OPTION 4, 6, or 9** to see components mounted on posts/platforms, helping you design the enclosure interior.

### Printing Instructions

1. **Software Required:**
   - [OpenSCAD](https://openscad.org/) - Free 3D CAD software
   - Slicer software (Cura, PrusaSlicer, etc.)

2. **Export STL files:**
   ```bash
   # Ensure OPTION 1 is uncommented in the file
   # Then render from command line
   openscad -o rs485_enclosure.stl rs485_enclosure.scad

   # Or open in OpenSCAD GUI and use File > Export > Export as STL
   ```

3. **Print Settings:**
   - **Material:** PLA or PETG recommended
   - **Layer Height:** 0.2mm
   - **Infill:** 20% (base), 15% (lid)
   - **Supports:** None required
   - **Print Orientation:**
     - Base: Print as-is (upright)
     - Lid: Print upside-down (already oriented in file)

4. **Post-Processing:**
   - Clean any stringing or blobs
   - Test-fit before assembly
   - Tap screw holes with M2.5 screws if needed

### Assembly

**Parts Needed:**
- 1x Printed base
- 1x Printed lid
- 4x M2.5 x 8mm screws (lid attachment)
- 2-4x M3 x 20mm screws + anchors (wall mounting, optional)
- 1x USB RS-485 adapter
- Cable glands or grommets (optional, for cleaner cable entry)

**Steps:**
1. Install all three components on their mounting posts/platforms in the base
2. Route RJ45 cable (carrying RS-485 + 24VAC) through left wall cable entry (14.6mm gland, centered)
3. Wire RS-485 signals (pins 1-4) from RJ45 cable to USB-RS485 adapter terminal
4. Wire 24VAC power (pins 5-8) from RJ45 cable to power adapter input
5. Wire 5VDC from power adapter output to Raspberry Pi power input (micro USB)
6. Connect USB-RS485 adapter to Raspberry Pi data port (micro USB) via short USB cable
7. Place lid on top, aligning the lip
8. Secure lid with 4x M2.5 screws
9. Mount to wall using M3 screws through corner mounting holes (optional)

### Customization

The design is fully parametric. Edit these parameters in the OpenSCAD file:

```openscad
// Enclosure dimensions (internal)
internal_width = 250;     // Width (X) - 25 cm default
internal_depth = 150;     // Depth (Y) - 15 cm default
internal_height = 50;     // Height (Z) - 5 cm default

// Wall thickness
wall = 2.5;               // Increase for more strength

// Cable entry
rj45_gland_diameter = 14.6;  // RJ45 cable gland diameter
```

### Variants

To create different versions:

1. **Raspberry Pi Version:** Increase dimensions to fit both RS-485 adapter and RPi
2. **DIN Rail Mount:** Replace mounting flanges with DIN rail clips
3. **Weatherproof:** Increase wall thickness, add gasket groove to lid

Edit the appropriate sections in the `.scad` file and re-render.

## Future Additions

Potential future designs:

- Raspberry Pi combo enclosure (RS-485 + RPi in one box)
- DIN rail mount adapter
- Weatherproof outdoor enclosure
- Cable management clips
- Breakout board mounting plate

## Contributing

If you create improvements or variants:

1. Add them as separate `.scad` files with descriptive names
2. Document in this README
3. Include STL files if desired (add to `.gitignore` if large)
4. Submit a pull request

## License

All hardware designs in this directory are released under the MIT License, matching the main project license.

## References

- [OpenSCAD Documentation](https://openscad.org/documentation.html)
- [Main Project Hardware Guide](../docs/connections/hardware.md)
- [Getting Started Guide](../getting-started.md)
