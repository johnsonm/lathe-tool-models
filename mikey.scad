// Copyright 2019 Michael K Johnson
// Use allowed under Attribution 4.0 International (CC BY 4.0) license terms
// https://creativecommons.org/licenses/by/4.0/legalcode
// Model of Mikey's Square, Knife, and Threading Tools
// https://www.hobby-machinist.com/threads/models-for-grinding-hss-lathe-tools.62111/
// Scale 200-500% for printing, reducing length, to see closely
// All parameters are in inches, because that's common use
// https://me-mechanicalengineering.com/single-point-cutting-tool/ has definitions

// Stock is assumed to be square in cross section
stock_width = 0.5;
// Typical stock is 3-6 inches long; can reduce to print enlarged models to concentrate on shape of nose tip
stock_len = 3;
// To model the curve from the wheel; 6" and 8" are common
wheel_diameter = 8;
// Wheel or platen thickness; matters only if using this for visualizations
wheel_thickness = 1;
// Radius of the edge of the wheel/platen; shows at back edge of top cut
wheel_edge_radius = .0625;
// Common radii are .0156 (1/64") .03125 (1/32") .0625 (1/16") (Nose radius currently ignored)
nose_radius = .03125;
knife_nose_radius = 0.0156;
// Side Cutting Edge Angle (SCEA)
side_cutting_edge_angle = 15;
// End Cutting Edge Angle (ECEA) is derived from the Nose Angle (NA, the included angle of the nose), which is normally less than 90
nose_angle = 80;
knife_nose_angle = 65;
threading_nose_angle = 60;
// Back Rake (BR) 
back_rake_angle = 15;
// Back Rake depth ratio (depth of back rake relative to stock width; reduce for high BR)
back_rake_depth_ratio = 1;
// Knife Back Rake (BR) (knife tool)
knife_back_rake_angle = 10;
// Side Rake (SR)
side_rake_angle = 15;
// Side Relief
side_relief_angle = 15;
// End Relief ("Clearance")
end_relief_angle = 15;
// How far back the top of the tool the side cut extends, relative to the width of the stock; typically between 1 and 2
side_edge_aspect_ratio = 1.5;
threading_side_edge_aspect_ratio = 0.5;
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
knife_nose_r = mm(knife_nose_radius);

// Logical pre-rounded nose tip located at -pivot_offset
function pivot_offset(scea=side_cutting_edge_angle, sear=side_edge_aspect_ratio) = -mm(sear * stock_width) * sin(scea);

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
module platen(h=wheel_r, t=wheel_t, d=wheel_t) {
    hull() {
        // front of platen
        translate([t/2, wheel_e_r, -h/2])
            cylinder(r=wheel_e_r, h=h, $fn=45);
        translate([-t/2, wheel_e_r, -h/2])
            cylinder(r=wheel_e_r, h=h, $fn=45);
        // extend it back to represent what will be cut out
        translate([t/2, d, -h/2])
            cylinder(r=wheel_e_r, h=h, $fn=45);
        translate([-t/2, d, -h/2])
            cylinder(r=wheel_e_r, h=h, $fn=45);
    }
}
module surface(t=wheel_t) {
    if (use_platen) {
        platen(t=t, d=t);
    } else {
        wheel(t=t);
    }
}
module stock(w=stock_w, l=stock_l, scea=side_cutting_edge_angle, sear=side_edge_aspect_ratio) {
    // origin is pivot point for cuts, oriented to be like using a wheel
    translate([pivot_offset(scea=scea, sear=sear), -l, -w])
        cube([w, l, w]);
}
function side_cut_z(scea=side_cutting_edge_angle) = 90-scea;
function ortho_angle(oa=side_cutting_edge_angle, ra=side_relief_angle) =
  // angles are measured orthogonal to the axes, but relief angles are cut against cutting angles
    asin(sin(ra)*cos(oa)) ;
function side_cut_t(br=back_rake_angle, era=end_relief_angle, sra=side_relief_angle, scea=side_cutting_edge_angle, sear=side_edge_aspect_ratio) = (scea*sra*era*br == 0) ? wheel_t : ((-pivot_offset(scea=scea, sear=sear))+(tan(sra)*stock_w)+(tan(era)*stock_w)+(tan(br)*stock_w)/sin(scea) + wheel_e_r*4) * 2;
module inner_side_cut(br=back_rake_angle, era=end_relief_angle, sra=side_relief_angle, scea=side_cutting_edge_angle, sear=side_edge_aspect_ratio) {
    z = side_cut_z(scea=scea);
    x = ortho_angle(oa=scea, ra=sra);
    echo (" - side table angle", x);
    t = side_cut_t(br=br, era=era, sra=sra, scea=scea, sear=sear);
    difference() {
        rotate([x, 0, 0]) // with the tool turned sideways this is x not y
        rotate([0, 0, -z])
            stock(scea=scea, sear=sear);
        surface(t=t);
    }
}
module side_cut(br=back_rake_angle, era=end_relief_angle, sra=side_relief_angle, scea=side_cutting_edge_angle, sear=side_edge_aspect_ratio) {
    z = side_cut_z(scea=scea);
    x = ortho_angle(oa=scea, ra=sra);
    rotate([0, 0, z])
    rotate([-x, 0, 0]) // with the tool turned sideways this is x not y
    inner_side_cut(br=br, era=era, sra=sra, scea=scea, sear=sear);
    // virtual protractor
    *#rotate([-90, 0, 0]) polygon(points=[[0, 0], [0, stock_w], [stock_w*sin(sra), stock_w]]);
    *#rotate([0, 0, -scea]) rotate([-90, 0, 0]) polygon(points=[[0, 0], [0, stock_w], [stock_w*sin(sra), stock_w]]);
}
*side_cut();
function end_cut_z(na=nose_angle, scea=side_cutting_edge_angle) = scea+(90-na);
module inner_end_cut(na=nose_angle, br=back_rake_angle, era=end_relief_angle, sra=side_relief_angle, scea=side_cutting_edge_angle, sear=side_edge_aspect_ratio) {
    z = end_cut_z(na=na, scea=scea);
    x = ortho_angle(oa=z, ra=era);
    echo (" - end table angle", x);
    difference() {
        rotate([x, 0, 0])
        rotate([0, 0, z])
            side_cut(br=br, era=era, sra=sra, scea=scea, sear=sear);
        translate([wheel_t/2-wheel_e_r, 0, 0]) surface();
    }
}
*inner_end_cut();
module end_cut(na=nose_angle, br=back_rake_angle, era=end_relief_angle, sra=side_relief_angle, scea=side_cutting_edge_angle, sear=side_edge_aspect_ratio) {
    z = end_cut_z(na=na, scea=scea);
    x = ortho_angle(oa=z, ra=era);
    rotate([0, 0, -z])
    rotate([-x, 0, 0])
    inner_end_cut(na=na, br=br, era=era, sra=sra, scea=scea, sear=sear);
    // virtual protractor
    po = -pivot_offset(scea=scea, sear=sear);
    *#translate([stock_w-po, -(stock_w-po)*sin(z), 0])
    rotate([-90, 0, -90])
    polygon(points=[[0, 0], [0, stock_w], [stock_w*sin(era), stock_w]]);
}
*end_cut();
module inner_nose_radius(nr=nose_r, na=nose_angle, br=back_rake_angle, era=end_relief_angle, sra=side_relief_angle, scea=side_cutting_edge_angle, sear=side_edge_aspect_ratio) {
    rz = end_cut_z(na=na, scea=scea);
    ry = ortho_angle(oa=scea, ra=sra);
    rx = ortho_angle(oa=rz, ra=era);
    union() {
        y = (nr / sin(na/2)) - (nr * sin(na/2));
        translate([0, -y, 0])
        difference() {
            translate([0, y, 0])
            rotate([0, 0, -na/2]) // bisect nose angle
            rotate([rx, 0, 0])
            rotate([0, ry, 0])
            rotate([0, 0, scea])
            end_cut(na=na, br=br, era=era, sra=sra, scea=scea, sear=sear);
            surface();
        }
        translate([0, -(nr / sin(na/2)), -1.5*stock_w])
        cylinder(r=nr, h=2*stock_w, $fn=30);
    }
}
*inner_nose_radius();
module nose_radius(nr=nose_r, na=nose_angle, br=back_rake_angle, era=end_relief_angle, sra=side_relief_angle, scea=side_cutting_edge_angle, sear=side_edge_aspect_ratio) {
    if (true) {
        end_cut(na=na, br=br, era=era, sra=sra, scea=scea, sear=sear);
    } else {
        // There is no chamfer function to make nose radius model easy
        // FIXME: these angles are not quite right
        rz = end_cut_z(na=na, scea=scea);
        ry = ortho_angle(oa=scea, ra=sra);
        rx = ortho_angle(oa=rz, ra=era);
        difference() {
            rotate([0, 0, -scea])
            rotate([0, -ry, 0])
            rotate([-rx, 0, 0])
            rotate([0, 0, na/2]) // bisect nose angle
            inner_nose_radius(nr=nr, na=na, br=br, era=era, sra=sra, scea=scea, sear=sear);
            union() {
                translate([0, stock_l-stock_w, stock_w])
                stock();
                translate([0, stock_l-stock_w, -stock_w])
                stock();
            }
        }
    }
}
*nose_radius();
function top_cut_z(br=back_rake_angle) = 90 + br;
module inner_top_cut(br=back_rake_angle, brdr=back_rake_depth_ratio, nr=nose_r, na=nose_angle, era=end_relief_angle, sra=side_relief_angle, scea=side_cutting_edge_angle, sear=side_edge_aspect_ratio, sr=side_rake_angle) {
    z = top_cut_z(br=br);
    difference() {
        rotate([sr, 0, 0])
        rotate([0, 0, z])
        rotate([0, 90, 0])
            nose_radius(nr=nr, na=na, br=br, era=era, sra=sra, scea=scea, sear=sear);
        surface(t=stock_w*2*brdr);
    }
}
module top_cut(br=back_rake_angle, brdr=back_rake_depth_ratio, nr=nose_r, na=nose_angle, era=end_relief_angle, sra=side_relief_angle, scea=side_cutting_edge_angle, sear=side_edge_aspect_ratio, sr=side_rake_angle) {
    z = top_cut_z(br=br);
    echo("    BR", br, "NR", nr, "NA", na, "ERA", era, "SRA", sra, "SCEA", scea, "SR", sr);
    rotate([0, -90, 0])
    rotate([0, 0, -z])
    rotate([-sr, 0, 0])
    inner_top_cut(br=br, brdr=brdr, nr=nr, na=na, era=era, sra=sra, scea=scea, sear=sear, sr=sr);
}
module square_tool(br=back_rake_angle, brdr=back_rake_depth_ratio, nr=nose_r, na=nose_angle, era=end_relief_angle, sra=side_relief_angle, scea=side_cutting_edge_angle, sear=side_edge_aspect_ratio, sr=side_rake_angle) {
    echo("Square tool:");
    top_cut(br=br, brdr=brdr, nr=nr, na=na, era=era, sra=sra, scea=scea, sear=sear, sr=sr);
}
module knife_tool(br=knife_back_rake_angle, brdr=back_rake_depth_ratio, nr=knife_nose_r, na=knife_nose_angle, era=end_relief_angle, sra=side_relief_angle, scea=0, sear=0, sr=side_rake_angle) {
    echo("Knife tool:");
    top_cut(br=br, brdr=brdr, nr=nr, na=na, era=era, sra=sra, scea=scea, sear=sear, sr=sr);
}
module threading_tool(br=0, nr=0, na=threading_nose_angle, era=end_relief_angle, sra=side_relief_angle, scea=threading_nose_angle/2, sear=threading_side_edge_aspect_ratio, sr=0) {
    // no top cut or nose radius
    echo("Threading tool:");
    echo("    BR", br, "NA", na, "ERA", era, "SRA", sra, "SCEA", scea);
    end_cut(na=na, br=br, era=era, sra=sra, scea=scea, sear=sear);
}
module demo_set() {
    translate([0, 0, 0]) {
        translate([wheel_t*0.4, 0, 0]) inner_side_cut();
        platen(d=wheel_e_r);
    }
    translate([wheel_t*1.5, 0, 0]) {
        inner_end_cut();
        platen(d=wheel_e_r);
    }
    translate([wheel_t*3, 0, 0]) {
        inner_top_cut();
        platen(d=wheel_e_r);
    }
}
module standard_set() {
    square_tool();
    translate([-2*stock_w, 0, 0]) knife_tool();
    translate([1.5*stock_w, 0, 0]) threading_tool();
}
*demo_set();
standard_set();
// aluminum
*translate([-3*stock_w, 0, 0]) square_tool(br=40, brdr=0.4, sr=18);
// stainless
*translate([-4.5*stock_w, 0, 0]) square_tool(br=10, era=13, sr=25, sear=1);
//square_tool();
//knife_tool();
//threading_tool();
