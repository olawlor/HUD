/*
Heads-up display for on-face use.

Dr. Orion Lawlor, lawlor@alaska.edu, 2020-11-14

"8-NIOSH-Medium" is from the standard NIOSH mask testing head model,
size "medium", from the "fit2face challenge" data packet:
    https://www.americamakes.us/fit2face/

*/

inch=25.4; // this file units = mm

// Angle of clear reflector plate in front of eyes
//  (0==reflector is parallel to eye view direction)
reflector_angle=45;

// This is the height were the optical centerline hits the reflector plate
reflector_forward=55; // mm height above eye center

// This is the height of the phone above the reflector plate
phone_above=110;

// This is the distance between the user's eyes (mostly debug)
ipd=67;

// Dimensions of reflector plate
reflector_thick=2.8; // mm thickness of plate
reflector_wide=60.0; // up and down
reflector_long=150; // side to side (across face)

glass_color=[0.3,0.5,0.7];
module reflector_outline(fatten=0.0) {
    color(glass_color)
    translate([0,0,reflector_forward])
        rotate([0,reflector_angle,0])
            cube([reflector_thick+2*fatten,reflector_long+2*fatten,reflector_wide+2*fatten],center=true);
}

// Phone: Moto g6 plus
phone_thick=10; // mm thickness, including case and a bit of wiggle room
phone_wide=78;
phone_long=163;
phone_edges=11; // amount to hold ends of phone

// Location of phone relative to eyes
phone_center=[phone_above,0,reflector_forward];

// Rotation of phone relative to eyes
phone_orient=[0,-2*reflector_angle,0];

module symmetry() {
    children();
    scale([1,-1,1]) children();
}

// Box of phone, starting from center of phone display screen
module phone_outline(fatten=0.0) {
    translate(phone_center)
    rotate(phone_orient)
    translate([0,0,phone_thick/2])
    {
        // Phone block:
        color([0.1,0.1,0.1])
            cube([phone_wide+2*fatten,phone_long+2*fatten,phone_thick+2*fatten],center=true);
        
        // View direction beams
        color([1,0,0])
        symmetry() translate([0,ipd/2,0])
            cylinder(d=3,h=phone_above);
    }
}

// Glasses: +3.0 diopter reading glasses, Sun Optics "Image Readers"
glasses_long=139; // between frames
glasses_frame=4; // diameter of thickest part of frame
glasses_height=11; // height of lenses above frame
glasses_thick_in=7; // thickness inside frame
glasses_thick_out=20; // thickness outside frame
glasses_thick=glasses_thick_in+glasses_thick_out;

glasses_center=[glasses_thick_in-glasses_thick/2,0,phone_above-25];

module glasses_frames(fatten=0.0,lenses=0) {
    translate(phone_center)
    rotate(phone_orient)
    translate(glasses_center)
    {
        // Actual glasses support frames (remove screws and earpieces)
        translate([0,glasses_long/2,0])
            cylinder(d=glasses_frame+2*fatten,h=12-0.01*fatten,center=true);
        // Optional lenses
        if (lenses) {
            scale([1,1,-1])
            color(glass_color)
            translate([-glasses_thick_in,-glasses_long/2,0])
                cube([glasses_thick_out+glasses_thick_in,glasses_long,glasses_height]);
        }
    }
}


// The sideplates are 3D printed flat on the build platform,
//  and hold everything else together
sideplate_origin=[25,glasses_long/2+4,reflector_forward-10];
sideplate_rotate=[0,0,6.5];

// Rotate our sideplate children into world coordinates.
//   (sideplates are printed flat on the build plate)
module world_from_sideplate() {
    translate(sideplate_origin)
    rotate(sideplate_rotate)
    rotate([90,0,0])
        children();
}
module sideplate_from_world() {
    rotate(-[90,0,0])
    rotate(-sideplate_rotate)
    translate(-sideplate_origin)
        children();
}

// Outlines to hold parts to the sideplates
module sideplate_holders()
{
    walls=2.0;
    wall_height=10;
    intersection() {
        sideplate_from_world()
        difference() {
            union() { // extra meat to hold parts in:
                reflector_outline(walls);
                phone_outline(walls);
                glasses_frames(walls);
            }
        }
        // Trim sideplates to hold parts
        translate([100-15,0,+wall_height/2])
            cube([200,200,wall_height],center=true);
    }
}

// The slideplate holds all the other stuff together
module sideplate()
{
    // Outside walls
    difference() {
        union() {
            sideplate_holders();
            
            // Baseplate
            difference() {
                scale([1,1,0.2]) hull() sideplate_holders();
                // Elliptical hole, to make part lighter
                translate([phone_above/3,15,0])
                    scale([2,1.1,1])
                        cylinder(d=35,h=20,center=true);
            }
            
            // Backmost spot for head contact
            head_back=[0,-55,0];
            // Leg, to reach back and align with the head
            hull() {
                for (spot=[
                    [0,5,0],
                    [0,-30,25],
                    head_back
                   ])
                    translate(spot)
                        cube([4,4,4]);
            }
            // Structural reinforcement diagonal
            translate(head_back)
            {
                cylinder(d=12,h=8);
                rotate([0,0,45])
                    cube([60,6,2]);
            }
        }
        
        // Space for actual parts
        sideplate_from_world()
            union() {
                reflector_outline();
                phone_outline();
                glasses_frames();
                niosh_outside();
            }
    }
}

module printable_sideplates() {
    symmetry(){
        translate([0,-60,0])
        sideplate();
    }
}

module functional_parts() {
    symmetry() world_from_sideplate() sideplate();
    #union() {
        reflector_outline();
        phone_outline();
        glasses_frames(0.0,1.0);
    }
    niosh_outside();
}


// Fix orientation of NIOSH head to standard printable
module niosh_to_standard() {
	translate([-7,0,-60])
	rotate([0,0,-90])
	 children();
}

module niosh_outside() {
	niosh_to_standard()
		//import("./8-NIOSH_medium_20k.stl",convexity=6);
    import("./NIOSH_large_20k.stl",convexity=4);
}


functional_parts();
// printable_sideplates();


