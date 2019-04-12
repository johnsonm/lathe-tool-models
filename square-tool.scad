// Copyright 2019 Michael K Johnson
// Use allowed under Attribution 4.0 International (CC BY 4.0) license terms
// https://creativecommons.org/licenses/by/4.0/legalcode
// Model of Mikey's Square Tool
// https://www.hobby-machinist.com/threads/models-for-grinding-hss-lathe-tools.62111/
// Scale 200-500% for printing, reducing length, to see closely
// All parameters are in inches, because that's common use
// https://me-mechanicalengineering.com/single-point-cutting-tool/ has definitions

// Stock is assumed to be square in cross section
stock_width = 0.5;
// Typical stock is 3-6 inches long; can reduce to print enlarged models to concentrate on shape of tip
stock_len = 3;
// To model the curve from the wheel; 6" and 8" are common
wheel_diameter = 8;
// Wheel or platen thickness; matters only if using this for visualizations
wheel_thickness = 1;
// Radius of the edge of the wheel/platen; shows at back edge of top cut
wheel_edge_radius = .0625;
// Common radii are .0156 (1/64") .03125 (1/32") .0625 (1/16") (Nose radius currently ignored)
nose_radius = .0156; // 1/64
// Side Cutting Edge Angle (SCEA)
side_cutting_edge_angle = 15;
// End Cutting Edge Angle (ECEA) is derived from the included angle of the tip, and is normally less than 90
tip_included_angle = 80;
// Back Rake (BR) 
back_rake_angle = 15;
// Side Rake (SR)
side_rake_angle = 15;
// Side Relief
side_relief_angle = 15;
// End Relief ("Clearance")
end_relief_angle = 15;
// How far back the top of the tool the side cut extends, relative to the width of the stock; typically between 1 and 2
side_edge_aspect_ratio = 1.5;
// use_platen: true for belt grinder platen, false for wheel grinder
use_platen = true;

/* [Hidden] */

// true to use simple shapes for fast rendering while developing; false for more accurate shapes for final renders
fast_render = false;

function mm(inches) = inches * 25.4;

stock_w = mm(stock_width);
stock_l = mm(stock_len);
wheel_r = mm(wheel_diameter) / 2;
wheel_t = mm(wheel_thickness);
wheel_e_r = mm(wheel_edge_radius);
nose_r = mm(nose_radius);

// Logical pre-rounded tip located at -pivot_offset
pivot_offset = -mm(side_edge_aspect_ratio * stock_width) * sin(side_cutting_edge_angle);
echo (pivot_offset);

module smooth_wheel(r=wheel_r, t=wheel_t) {
    x = t/2 - wheel_e_r;
    y = r - mm(0.5);
    translate([0, r, 0])
    rotate([0, 90, 0])
    rotate_extrude($fa=1)
    rotate([0, 0, 90])
    translate([0, -(r-wheel_e_r), 0])
    hull() {
        translate([x, 0, 0]) circle(r=wheel_e_r, $fn=45);
        translate([-x, 0, 0]) circle(r=wheel_e_r, $fn=45);
        translate([x, y, 0]) circle(r=wheel_e_r, $fn=45);
        translate([-x, y, 0]) circle(r=wheel_e_r, $fn=45);
    }
}
module wheel(r=wheel_r, t=wheel_t) {
    z = -stock_w/2; // honed angles at edges will be as set
    // simple cylinder
    if (fast_render) {
        translate([-t/2, r, z]) rotate([90, 0, 90])
        cylinder(r=r, h=t, $fa=1);
    } else {
        smooth_wheel(r, t);
    }
}
module platen(h=wheel_r, t=wheel_t) {
    hull() {
        // front of platen
        translate([t/2, wheel_e_r, -h/2])
            cylinder(r=wheel_e_r, h=h, $fn=45);
        translate([-t/2, wheel_e_r, -h/2])
            cylinder(r=wheel_e_r, h=h, $fn=45);
        // extend it back to represent what will be cut out
        translate([t/2, t, -h/2])
            cylinder(r=wheel_e_r, h=h, $fn=45);
        translate([-t/2, t, -h/2])
            cylinder(r=wheel_e_r, h=h, $fn=45);
    }
}
module surface(t=wheel_t) {
    if (use_platen) {
        platen(t=t);
    } else {
        wheel(t=t);
    }
}
module stock(w=stock_w, l=stock_l) {
    // origin is pivot point for cuts, oriented to be like using a wheel
    translate([pivot_offset, -l, -w])
        cube([w, l, w]);
}
module side_cut() {
    z = 90-side_cutting_edge_angle;
    rotate([0, -side_relief_angle, 0])
    rotate([0, 0, z])
    difference() {
        rotate([0, 0, -z])
        rotate([0, side_relief_angle, 0])
            stock();
        surface(t=wheel_t*10); // "infinite" wheel, move stock
    }
}
module end_cut() {
    z = (90-tip_included_angle)+side_cutting_edge_angle;
    rotate([0, 0, -z])
    rotate([-end_relief_angle, 0, 0])
    difference() {
        rotate([end_relief_angle, 0, 0])
        rotate([0, 0, z])
            side_cut();
        surface();
    }
}
module nose_radius() {
    // There is no chamfer function to follow the
    // the sharp edge with a clean curve
    // Should find a way to sufficiently approximate
    end_cut();
}
module top_cut() {
    z = 90 + back_rake_angle;
    rotate([0, -90, 0])
    rotate([0, 0, -z])
    difference() {
        rotate([0, 0, z])
        rotate([0, 90, 0])
            nose_radius();
        surface();
    }
}
//wheel();
//platen();
top_cut();