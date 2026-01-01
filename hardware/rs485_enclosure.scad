// RS-485 to USB Adapter Enclosure for WaterFurnace Aurora
// Designed to house a USB RS-485 adapter with cable pass-throughs
// License: MIT

// ===== PARAMETERS =====

// Enclosure dimensions (internal) - sized for all three components with ample space
internal_width = 250;     // Width (X) - 25 cm long
internal_depth = 150;     // Depth (Y) - 15 cm wide
internal_height = 50;     // Height (Z) - 5 cm deep

// Wall thickness
wall = 2.5;              // Wall thickness
base_thickness = 2;      // Bottom thickness
lid_thickness = 2;       // Top thickness

// Cable entry
rj45_gland_diameter = 14.6;  // Diameter for RJ45 cable gland (carries both RS-485 and 24VAC)
usb_width = 13;              // Width of USB connector opening
usb_height = 7;              // Height of USB connector opening

// Mounting
mounting_hole_dia = 3.5; // Diameter for M3 screws
mounting_hole_offset = 5; // Distance from corners

// Lid attachment
lid_screw_dia = 2.5;     // M2.5 screws for lid
lid_screw_count = 4;     // Number of lid screws

// Tolerances
tolerance = 0.2;         // Gap between lid and base
screw_clearance = 0.3;   // Additional clearance for screw holes

// ===== COMPUTED VALUES =====

outer_width = internal_width + 2 * wall;
outer_depth = internal_depth + 2 * wall;
base_height = internal_height + base_thickness;
lid_height = lid_thickness + 2;

// ===== RASPBERRY PI ZERO W REFERENCE MODEL =====

// Raspberry Pi Zero W Ver 1.1 - Detailed Reference Model
// Use this to design the enclosure with proper clearances

module raspberry_pi_zero_w(show_keepouts=true) {
    // Board dimensions
    pcb_length = 65;      // X direction
    pcb_width = 30;       // Y direction
    pcb_thickness = 1.6;  // Standard PCB thickness
    component_height = 5; // Total height including components

    // Mounting holes - M2.5
    mount_hole_dia = 2.75;        // Drilled diameter (tolerance +/- 0.05mm)
    mount_hole_from_edge = 3.5;   // Distance from edge to hole center

    // SD card slot (left edge, centered at 16.9mm from bottom)
    sd_card_y_center = 16.9;      // From bottom edge to centerline
    sd_card_clearance = 20;       // Required clearance to left for removal
    sd_card_width = 11.5;         // SD card slot width
    sd_card_depth = 1.5;          // Protrusion from board edge
    sd_card_height = 1.5;         // Slot height

    // Micro USB connectors (bottom edge)
    microusb_width = 7.5;         // Connector width
    microusb_height = 3;          // Connector height
    microusb_depth = 6;           // Protrusion from board edge

    usb_rs485_x_center = 41.4;    // RS485 USB - distance from left edge
    usb_power_x_center = 54;      // Power USB - distance from left edge

    // Mini HDMI (right edge, approximate)
    hdmi_x_center = 12.4;         // From right edge
    hdmi_width = 11.2;
    hdmi_height = 3.5;
    hdmi_depth = 6;

    // GPIO Header location (top edge, approximate)
    gpio_x_start = 3.5;           // From left edge
    gpio_y_from_top = 3.5;        // From top edge
    gpio_pin_count = 40;
    gpio_length = 51;             // 2x20 header length
    gpio_width = 5;               // Header width
    gpio_height = 8.5;            // Height when populated

    color("green", 0.9) {
        // Main PCB body
        difference() {
            cube([pcb_length, pcb_width, pcb_thickness]);

            // Mounting holes
            mounting_hole_positions = [
                [mount_hole_from_edge, mount_hole_from_edge],
                [pcb_length - mount_hole_from_edge, mount_hole_from_edge],
                [mount_hole_from_edge, pcb_width - mount_hole_from_edge],
                [pcb_length - mount_hole_from_edge, pcb_width - mount_hole_from_edge]
            ];

            for (pos = mounting_hole_positions) {
                translate([pos[0], pos[1], -0.5])
                    cylinder(h=pcb_thickness+1, d=mount_hole_dia, $fn=24);
            }
        }

        // Component height indicator (simplified)
        translate([5, 5, pcb_thickness])
            cube([pcb_length-10, pcb_width-10, component_height-pcb_thickness]);
    }

    // SD Card Slot (left edge)
    color("silver", 0.8)
        translate([-sd_card_depth, sd_card_y_center - sd_card_width/2, pcb_thickness])
        cube([sd_card_depth, sd_card_width, sd_card_height]);

    // Micro USB - RS485 (bottom edge)
    color("silver", 0.8)
        translate([usb_rs485_x_center - microusb_width/2, -microusb_depth, pcb_thickness])
        cube([microusb_width, microusb_depth, microusb_height]);

    // Micro USB - Power (bottom edge)
    color("silver", 0.8)
        translate([usb_power_x_center - microusb_width/2, -microusb_depth, pcb_thickness])
        cube([microusb_width, microusb_depth, microusb_height]);

    // Mini HDMI (right edge)
    color("silver", 0.8)
        translate([pcb_length - hdmi_x_center - hdmi_width/2, pcb_width, pcb_thickness])
        cube([hdmi_width, hdmi_depth, hdmi_height]);

    // Keepout zones (clearances needed)
    if (show_keepouts) {
        // SD card removal clearance (left side)
        color("red", 0.2)
            translate([-sd_card_clearance, sd_card_y_center - sd_card_width/2 - 2, 0])
            cube([sd_card_clearance - sd_card_depth, sd_card_width + 4, 15]);

        // USB connector access (bottom)
        color("blue", 0.2)
            translate([usb_rs485_x_center - microusb_width/2 - 2, -microusb_depth - 10, 0])
            cube([microusb_width + 4, 10, 8]);

        color("blue", 0.2)
            translate([usb_power_x_center - microusb_width/2 - 2, -microusb_depth - 10, 0])
            cube([microusb_width + 4, 10, 8]);
    }
}

// Mounting posts for Raspberry Pi Zero W
// Place these in your enclosure base
module pi_zero_mounting_posts(post_height=3, post_dia=5.5, hole_dia=2.2) {
    // Post positions relative to Pi Zero origin
    mount_hole_from_edge = 3.5;
    pcb_length = 65;
    pcb_width = 30;

    positions = [
        [mount_hole_from_edge, mount_hole_from_edge],
        [pcb_length - mount_hole_from_edge, mount_hole_from_edge],
        [mount_hole_from_edge, pcb_width - mount_hole_from_edge],
        [pcb_length - mount_hole_from_edge, pcb_width - mount_hole_from_edge]
    ];

    for (pos = positions) {
        translate([pos[0], pos[1], 0])
            difference() {
                cylinder(h=post_height, d=post_dia, $fn=24);
                // Pilot hole for M2.5 screw (2.2mm for self-tapping, 2.5mm for clearance)
                translate([0, 0, -0.5])
                    cylinder(h=post_height+1, d=hole_dia, $fn=16);
            }
    }
}

// ===== 24VAC TO 5VDC POWER ADAPTER REFERENCE MODEL =====

// 24VAC to 5VDC Power Adapter Board - Detailed Reference Model
// Use this to design the enclosure with proper clearances

module power_adapter_24vac_5vdc(show_keepouts=true) {
    // Board dimensions
    board_length = 49;        // X direction
    board_width = 26;         // Y direction
    board_height = 22;        // Total height including components
    pcb_thickness = 1.6;      // PCB thickness (typical)

    // Mounting holes - M3
    mount_hole_dia = 3;           // 3mm holes
    mount_hole_from_edge = 2.5;   // Distance from edge to hole center

    // Wire connectors
    connector_width = 10;         // Wire connector width
    connector_depth = 8;          // Protrusion from board edge
    connector_height = 8;         // Connector height

    // AC input (left side)
    ac_connector_y_center = board_width / 2;  // Centered on edge

    // DC output (right side)
    dc_connector_y_center = board_width / 2;  // Centered on edge

    // Wire clearance
    wire_clearance = 15;          // Clearance needed for wires + bending

    color("blue", 0.8) {
        // Main board body (simplified as solid block)
        difference() {
            cube([board_length, board_width, board_height]);

            // Mounting holes
            mounting_hole_positions = [
                [mount_hole_from_edge, mount_hole_from_edge],
                [board_length - mount_hole_from_edge, mount_hole_from_edge],
                [mount_hole_from_edge, board_width - mount_hole_from_edge],
                [board_length - mount_hole_from_edge, board_width - mount_hole_from_edge]
            ];

            for (pos = mounting_hole_positions) {
                translate([pos[0], pos[1], -0.5])
                    cylinder(h=board_height+1, d=mount_hole_dia, $fn=24);
            }
        }
    }

    // AC input connector (left side)
    color("green", 0.8)
        translate([-connector_depth, ac_connector_y_center - connector_width/2, 0])
        cube([connector_depth, connector_width, connector_height]);

    // DC output connector (right side)
    color("red", 0.8)
        translate([board_length, dc_connector_y_center - connector_width/2, 0])
        cube([connector_depth, connector_width, connector_height]);

    // Keepout zones (clearances needed)
    if (show_keepouts) {
        // AC input wire clearance (left side)
        color("orange", 0.2)
            translate([-connector_depth - wire_clearance, ac_connector_y_center - connector_width/2 - 5, 0])
            cube([wire_clearance, connector_width + 10, connector_height + 5]);

        // DC output wire clearance (right side)
        color("purple", 0.2)
            translate([board_length + connector_depth, dc_connector_y_center - connector_width/2 - 5, 0])
            cube([wire_clearance, connector_width + 10, connector_height + 5]);

        // Top clearance for heat dissipation
        color("yellow", 0.15)
            translate([5, 5, board_height])
            cube([board_length-10, board_width-10, 10]);
    }
}

// Mounting posts for power adapter board
// Place these in your enclosure base
module power_adapter_mounting_posts(post_height=3, post_dia=6, hole_dia=2.5) {
    // Post positions relative to power adapter origin
    mount_hole_from_edge = 2.5;
    board_length = 49;
    board_width = 26;

    positions = [
        [mount_hole_from_edge, mount_hole_from_edge],
        [board_length - mount_hole_from_edge, mount_hole_from_edge],
        [mount_hole_from_edge, board_width - mount_hole_from_edge],
        [board_length - mount_hole_from_edge, board_width - mount_hole_from_edge]
    ];

    for (pos = positions) {
        translate([pos[0], pos[1], 0])
            difference() {
                cylinder(h=post_height, d=post_dia, $fn=24);
                // Pilot hole for M3 screw (2.5mm for self-tapping, 3mm for clearance)
                translate([0, 0, -0.5])
                    cylinder(h=post_height+1, d=hole_dia, $fn=16);
            }
    }
}

// ===== USB TO RS485 ADAPTER REFERENCE MODEL =====

// USB to RS485 Adapter - Detailed Reference Model
// Use this to design the enclosure with proper clearances

module usb_rs485_adapter(show_keepouts=true) {
    // Main body dimensions
    body_length = 53;         // X direction (main PCB)
    body_width = 23.5;        // Y direction
    body_height = 14.3;       // Z direction (total height)

    // USB-A connector (left side, protrudes)
    usb_length = 12.7;        // Protrusion from body
    usb_width = 11.8;         // Connector width
    usb_height = 4.5;         // Standard USB-A height
    usb_y_offset = (body_width - usb_width) / 2;  // Center on body

    // RS485 terminal connector (right side, protrudes)
    rs485_length = 9;         // Protrusion depth
    rs485_width = 12.2;       // Connector width
    rs485_height = 11.4;      // Connector height
    rs485_y_offset = (body_width - rs485_width) / 2;  // Center on body

    // Cable clearances
    usb_cable_clearance = 25;     // Space needed for USB cable + bend radius
    rs485_wire_clearance = 20;    // Space needed for RS485 wires

    // Main adapter body
    color("darkgreen", 0.8) {
        cube([body_length, body_width, body_height]);
    }

    // USB-A connector (left side, protruding)
    color("silver", 0.8)
        translate([-usb_length, usb_y_offset, body_height/2 - usb_height/2])
        cube([usb_length, usb_width, usb_height]);

    // RS485 terminal block (right side, protruding)
    color("green", 0.8)
        translate([body_length, rs485_y_offset, 0])
        cube([rs485_length, rs485_width, rs485_height]);

    // Status LED indicator (simplified)
    color("red", 0.9)
        translate([body_length/2, body_width/2, body_height - 0.5])
        cylinder(h=1, d=3, $fn=16);

    // Keepout zones (clearances needed)
    if (show_keepouts) {
        // USB cable clearance (left side)
        color("cyan", 0.2)
            translate([-usb_length - usb_cable_clearance, usb_y_offset - 5, 0])
            cube([usb_cable_clearance, usb_width + 10, body_height + 10]);

        // RS485 wire clearance (right side)
        color("magenta", 0.2)
            translate([body_length + rs485_length, rs485_y_offset - 5, 0])
            cube([rs485_wire_clearance, rs485_width + 10, rs485_height + 5]);

        // Top clearance for viewing status LED
        color("yellow", 0.1)
            translate([body_length/2 - 10, body_width/2 - 10, body_height])
            cube([20, 20, 5]);
    }
}

// Simple platform/support for USB-RS485 adapter
// Since these adapters typically don't have mounting holes,
// create a platform with side supports or clips
module usb_rs485_platform(platform_height=2, with_clips=true) {
    body_length = 53;
    body_width = 23.5;
    body_height = 14.3;

    // Base platform
    color("white", 0.5)
        cube([body_length, body_width, platform_height]);

    if (with_clips) {
        clip_height = 5;
        clip_thickness = 2;
        clip_overhang = 2;

        // Side clips to hold adapter in place
        // Left clip
        translate([10, -clip_thickness, platform_height])
            cube([8, clip_thickness, clip_height]);
        translate([10, -clip_thickness, platform_height + clip_height - clip_overhang])
            cube([8, clip_thickness + clip_overhang, clip_overhang]);

        // Right clip
        translate([body_length - 18, -clip_thickness, platform_height])
            cube([8, clip_thickness, clip_height]);
        translate([body_length - 18, -clip_thickness, platform_height + clip_height - clip_overhang])
            cube([8, clip_thickness + clip_overhang, clip_overhang]);

        // Mirror clips on other side
        translate([0, body_width, 0])
            mirror([0, 1, 0]) {
                translate([10, -clip_thickness, platform_height])
                    cube([8, clip_thickness, clip_height]);
                translate([10, -clip_thickness, platform_height + clip_height - clip_overhang])
                    cube([8, clip_thickness + clip_overhang, clip_overhang]);

                translate([body_length - 18, -clip_thickness, platform_height])
                    cube([8, clip_thickness, clip_height]);
                translate([body_length - 18, -clip_thickness, platform_height + clip_height - clip_overhang])
                    cube([8, clip_thickness + clip_overhang, clip_overhang]);
            }
    }
}

// ===== COMPONENT LAYOUT =====

// Complete component assembly positioned for the enclosure
// This shows how all three components fit together
module component_assembly(show_keepouts=false) {
    // Position offsets from internal cavity origin (after wall offset)
    // All positions match the mounting structures in enclosure_base
    // Spread out in 25cm x 15cm enclosure for optimal access and cooling

    // USB-RS485 adapter - front left area
    // RJ45 cable (RS-485 + 24VAC) exits through front wall to heat pump
    // USB connector routes internally to Pi
    translate([30, 30, 0]) {
        // Platform at base level
        usb_rs485_platform(platform_height=2, with_clips=true);
        // Adapter sits on top of platform
        translate([0, 0, 2])
            usb_rs485_adapter(show_keepouts=show_keepouts);
    }

    // Power adapter - back left area
    // AC input wired from RJ45 cable (24VAC), DC output routes to Pi
    translate([30, 90, 0]) {
        // Mounting posts at base level
        power_adapter_mounting_posts(post_height=3, post_dia=6, hole_dia=2.5);
        // Power board sits on top of posts
        translate([0, 0, 3])
            power_adapter_24vac_5vdc(show_keepouts=show_keepouts);
    }

    // Raspberry Pi Zero W - right side, centered vertically
    // USB ports connect to RS485 adapter, power from power adapter
    // SD card accessible from right wall or through lid
    translate([170, 90, 0]) {
        // Mounting posts at base level (10mm tall)
        pi_zero_mounting_posts(post_height=10, post_dia=5.5, hole_dia=2.2);
        // Pi board sits on top of posts
        translate([0, 0, 10])
            raspberry_pi_zero_w(show_keepouts=show_keepouts);
    }
}

// ===== MODULES =====

// Main enclosure base
module enclosure_base() {
    difference() {
        union() {
            // Main box
            cube([outer_width, outer_depth, base_height]);

            // Mounting flanges
            translate([0, 0, 0])
                mounting_flange();
        }

        // Internal cavity
        translate([wall, wall, base_thickness])
            cube([internal_width, internal_depth, internal_height + 1]);

        // === CABLE ENTRY/EXIT OPENINGS ===

        // RJ45 cable from heat pump (left wall, at 75% depth)
        // This cable carries BOTH RS-485 signals (pins 1-4) and 24VAC power (pins 5-8)
        // Positioned at 75% depth to avoid lid screw posts
        translate([-1, outer_depth * 0.75, base_height/2])
            rotate([0, 90, 0])
            cylinder(h=wall+2, d=rj45_gland_diameter, $fn=32);

        // Optional: micro USB access for Pi (can be accessed by removing lid)
        // If you want direct access without removing lid, uncomment:
        // translate([outer_width - wall - 1, wall + 20 + 15, base_thickness + 6])
        //     rotate([0, 90, 0])
        //     cube([8, 20, wall+2]);

        // Mounting holes in flanges
        mounting_holes();

        // Lid screw holes
        lid_screw_holes();

        // Label recess
        translate([outer_width/2, outer_depth - wall/2 - 1, base_thickness])
            rotate([90, 0, 0])
            linear_extrude(height=0.6)
            text("RS-485", size=5, halign="center", valign="bottom", font="Liberation Sans:style=Bold");

        translate([outer_width/2, outer_depth - wall/2 - 1, base_thickness + 7])
            rotate([90, 0, 0])
            linear_extrude(height=0.6)
            text("WaterFurnace", size=4, halign="center", valign="bottom", font="Liberation Sans");
    }

    // Screw posts for lid
    lid_screw_posts();

    // === COMPONENT MOUNTING ===

    // USB-RS485 adapter platform (front left area)
    translate([wall + 30, wall + 30, base_thickness])
        usb_rs485_platform(platform_height=2, with_clips=true);

    // Power adapter mounting posts (back left area)
    translate([wall + 30, wall + 90, base_thickness])
        power_adapter_mounting_posts(post_height=3, post_dia=6, hole_dia=2.5);

    // Raspberry Pi Zero mounting posts (right side, moved 30mm right and 30mm up)
    translate([wall + 170, wall + 90, base_thickness])
        pi_zero_mounting_posts(post_height=10, post_dia=5.5, hole_dia=2.2);
}

// Enclosure lid
module enclosure_lid() {
    difference() {
        union() {
            // Main lid
            cube([outer_width - tolerance*2, outer_depth - tolerance*2, lid_thickness]);

            // Lip for alignment
            translate([wall - tolerance, wall - tolerance, -2])
                cube([internal_width + tolerance*2, internal_depth + tolerance*2, 2]);
        }

        // Screw holes
        for (i = [0:lid_screw_count-1]) {
            angle = i * 360 / lid_screw_count;
            x = outer_width/2 + cos(angle) * (internal_width/2 - 5);
            y = outer_depth/2 + sin(angle) * (internal_depth/2 - 5);

            translate([x - tolerance, y - tolerance, -1])
                cylinder(h=lid_thickness+2, d=lid_screw_dia + screw_clearance, $fn=16);

            // Countersink
            translate([x - tolerance, y - tolerance, lid_thickness - 1.5])
                cylinder(h=2, d1=lid_screw_dia + screw_clearance, d2=lid_screw_dia*2, $fn=16);
        }

        // Ventilation slots
        for (i = [-1:1]) {
            translate([outer_width/2 + i*12 - tolerance, outer_depth/2 - 15 - tolerance, -1])
                cube([2, 30, lid_thickness+2]);
        }

        // Top label
        translate([outer_width/2 - tolerance, outer_depth/2 - tolerance, lid_thickness - 0.6])
            linear_extrude(height=0.7)
            text("AURORA", size=6, halign="center", valign="center", font="Liberation Sans:style=Bold");
    }
}

// Mounting flange
module mounting_flange() {
    flange_size = mounting_hole_offset * 2 + mounting_hole_dia + 4;
    flange_thickness = 3;

    // Corner flanges
    positions = [
        [0, 0],
        [outer_width - flange_size, 0],
        [0, outer_depth - flange_size],
        [outer_width - flange_size, outer_depth - flange_size]
    ];

    for (pos = positions) {
        translate([pos[0], pos[1], 0])
            difference() {
                cube([flange_size, flange_size, flange_thickness]);
            }
    }
}

// Mounting holes
module mounting_holes() {
    positions = [
        [mounting_hole_offset, mounting_hole_offset],
        [outer_width - mounting_hole_offset, mounting_hole_offset],
        [mounting_hole_offset, outer_depth - mounting_hole_offset],
        [outer_width - mounting_hole_offset, outer_depth - mounting_hole_offset]
    ];

    for (pos = positions) {
        translate([pos[0], pos[1], -1])
            cylinder(h=base_thickness+2, d=mounting_hole_dia, $fn=24);

        // Countersink from bottom
        translate([pos[0], pos[1], -1])
            cylinder(h=1.5, d1=mounting_hole_dia*2, d2=mounting_hole_dia, $fn=24);
    }
}

// Lid screw posts
module lid_screw_posts() {
    for (i = [0:lid_screw_count-1]) {
        angle = i * 360 / lid_screw_count;
        x = outer_width/2 + cos(angle) * (internal_width/2 - 5);
        y = outer_depth/2 + sin(angle) * (internal_depth/2 - 5);

        translate([x, y, base_thickness])
            difference() {
                cylinder(h=internal_height, d=6, $fn=24);
                // Pilot hole for self-tapping screw
                translate([0, 0, -1])
                    cylinder(h=internal_height+2, d=2, $fn=16);
            }
    }
}

// Screw holes for lid attachment
module lid_screw_holes() {
    // These are just clearance holes in the posts
    // Actual screw holes are created in lid_screw_posts
}

// Cable strain relief clip (optional separate part)
// For RJ45 cable with 14.6mm gland
module strain_relief_clip() {
    cable_dia = rj45_gland_diameter;

    difference() {
        union() {
            cylinder(h=10, d=cable_dia+4, $fn=32);
            translate([-(cable_dia+4)/2, 0, 0])
                cube([cable_dia+4, (cable_dia+4)/2, 10]);
        }

        translate([0, 0, -1])
            cylinder(h=12, d=cable_dia+0.5, $fn=32);

        // Slit for installation
        translate([-(cable_dia+0.5)/2, 0, -1])
            cube([cable_dia+0.5, (cable_dia+4), 12]);

        // Screw hole
        translate([0, (cable_dia+4)/2 + 1, 5])
            rotate([90, 0, 0])
            cylinder(h=cable_dia+4, d=2.5, $fn=16);
    }
}

// ===== RENDERING =====

// Uncomment the part you want to render:

// OPTION 1: For printing - base and lid separate
enclosure_base();

translate([outer_width + 10, 0, lid_thickness])
    rotate([180, 0, 0])
    enclosure_lid();

// OPTION 2: For visualization - assembled view
//enclosure_base();
//translate([tolerance, tolerance, base_height])
//    enclosure_lid();

// OPTION 3: Raspberry Pi Zero W reference model (for design verification)
// Visualize the Pi with keepout zones to ensure proper clearances
//raspberry_pi_zero_w(show_keepouts=true);

// OPTION 4: Pi Zero with mounting posts (for enclosure design)
// Shows how the Pi will mount inside the enclosure
//translate([0, 0, 0]) {
//    pi_zero_mounting_posts(post_height=3, post_dia=5.5, hole_dia=2.2);
//    translate([0, 0, 3])
//        raspberry_pi_zero_w(show_keepouts=true);
//}

// OPTION 5: 24VAC to 5VDC power adapter reference model
// Visualize the power adapter with keepout zones
//power_adapter_24vac_5vdc(show_keepouts=true);

// OPTION 6: Power adapter with mounting posts
//translate([0, 0, 0]) {
//    power_adapter_mounting_posts(post_height=3, post_dia=6, hole_dia=2.5);
//    translate([0, 0, 3])
//        power_adapter_24vac_5vdc(show_keepouts=true);
//}

// OPTION 7: Complete system visualization (Pi + Power Adapter + mounting)
// Shows how both boards fit together with proper spacing
//translate([0, 0, 0]) {
//    // Power adapter at base level
//    power_adapter_mounting_posts(post_height=3, post_dia=6, hole_dia=2.5);
//    translate([0, 0, 3])
//        power_adapter_24vac_5vdc(show_keepouts=false);
//
//    // Pi Zero above power adapter
//    translate([0, 35, 0]) {
//        pi_zero_mounting_posts(post_height=3, post_dia=5.5, hole_dia=2.2);
//        translate([0, 0, 3])
//            raspberry_pi_zero_w(show_keepouts=false);
//    }
//}

// OPTION 8: USB to RS485 adapter reference model
// Visualize the USB-RS485 adapter with keepout zones
//usb_rs485_adapter(show_keepouts=true);

// OPTION 9: USB-RS485 adapter with platform/clips
//translate([0, 0, 0]) {
//    usb_rs485_platform(platform_height=2, with_clips=true);
//    translate([0, 0, 2])
//        usb_rs485_adapter(show_keepouts=true);
//}

// OPTION 10: Complete system with all three components (standalone)
// Shows Pi, Power Adapter, and USB-RS485 adapter together without enclosure
// Layout optimized for 25cm x 15cm enclosure
//translate([0, 0, 0]) {
//    // USB-RS485 adapter - front left
//    translate([30, 30, 0]) {
//        usb_rs485_platform(platform_height=2, with_clips=false);
//        translate([0, 0, 2])
//            usb_rs485_adapter(show_keepouts=false);
//    }
//
//    // Power adapter - back left
//    translate([30, 90, 0]) {
//        power_adapter_mounting_posts(post_height=3, post_dia=6, hole_dia=2.5);
//        translate([0, 0, 3])
//            power_adapter_24vac_5vdc(show_keepouts=false);
//    }
//
//    // Pi Zero - right side, centered
//    translate([140, 60, 0]) {
//        pi_zero_mounting_posts(post_height=3, post_dia=5.5, hole_dia=2.2);
//        translate([0, 0, 3])
//            raspberry_pi_zero_w(show_keepouts=false);
//    }
//}

// OPTION 11: Enclosure with all components assembled inside
// Shows the complete working system with proper mounting and positioning
//color("lightgray", 0.3) enclosure_base();  // Semi-transparent base
//translate([wall, wall, base_thickness])  // Align with base cavity
//    component_assembly(show_keepouts=false);
//color("lightblue", 0.2) translate([tolerance, tolerance, base_height])
//    enclosure_lid();  // Semi-transparent lid

// OPTION 12: Exploded view - shows how everything fits together
// Useful for assembly visualization
//enclosure_base();
//translate([wall, wall, base_height + 20])  // Components lifted above base
//    component_assembly(show_keepouts=false);
//translate([tolerance, tolerance, base_height + 50])  // Lid above components
//    enclosure_lid();

// Strain relief clip (optional separate part)
//translate([outer_width + 10, outer_depth/2, 0])
//    strain_relief_clip();
