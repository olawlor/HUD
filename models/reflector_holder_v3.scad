/*
Heads-up display for on-face use.

Dr. Orion Lawlor, lawlor@alaska.edu, 2020-11-14

"8-NIOSH-Medium" is from the standard NIOSH mask testing head model,
size "medium", from the "fit2face challenge" data packet:
    https://www.americamakes.us/fit2face/

*/
$fs=0.1;
$fa=5;
inch=25.4; // this file units = mm

// Angle of clear reflector plate in front of eyes
//  (0==reflector is parallel to eye view direction)
reflector_angle=45;

// Thickness of thinner walls
thinwall=1.5;

// This is the height were the optical centerline hits the reflector plate
reflector_forward=65; // mm height above eye center

// This is the distance between the focusing lens and phone
//  100mm = 1/10 meter => +10 diopter lens
focal_length=100;

// The lens thickness, for optical path length
lens_thick_optical=5;

// The lens thickness, for mechanical mounting
lens_thick_mechanical=11;

// The lens outside diameter (mounting hole)
lens_OD=54;
lens_ID=50; // inside diameter, through hole

// This is the distance between the user's eyes (sets the lens positions)
ipd=67;
lens_centerX=25; // reflector-to-lens distance
lens_centerY=ipd/2;
lens_centerZ=reflector_forward;

// This is the height of the phone above the reflector plate
phone_above=lens_centerX+focal_length;

// Dimensions of reflector plate
reflector_thick=2.8; // mm thickness of plate
reflector_wide=68.0; // up and down
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

// The actual mounted piece of glass
module lens() {
	translate([lens_centerX,lens_centerY,lens_centerZ])
	rotate([0,90,0])
	{
		translate([0,0,+1]) // hole for lens
		cylinder(d=lens_OD,h=lens_thick_mechanical); 
		translate([0,0,-1]) // hole for light
		cylinder(d=lens_ID,h=lens_thick_mechanical+2);
	}
}
module lenses() { symmetry() lens(); }

// Holds one lens
module lens_ring() {
	translate([lens_centerX,lens_centerY,lens_centerZ])
	rotate([0,90,0])
	difference() {
		// outside ring
		cylinder(d=lens_OD+2*thinwall,h=lens_thick_mechanical); 
	}
}


// This tube holds the lens rings in place
module lens_frame(start=-1) {
	translate([lens_centerX+lens_thick_mechanical/2,0,0])
	{
		for (frontback=[start:2:+1])
		translate([0,
				lens_centerY+10,lens_centerZ+frontback*lens_OD/2])
			rotate([90,0,0])
			difference() {
				// basically a hollow tube, with space for a rod to connect the halves
				cylinder(d=6,h=85,center=true);
				cylinder(d=3.2,h=100,center=true);
			}
		if (start==-1) { // include bottom plate
			// Flat around lens
			// supports ring during print, and blocks light
			translate([0,lens_centerY,lens_centerZ-lens_OD/2])
				cube([thinwall,50,lens_OD]);
			// Same thing in +X axis
			translate([-lens_thick_mechanical/2,lens_centerY,lens_centerZ])
				cube([lens_thick_mechanical,50,thinwall]);
			
		}
	}
}


// The sideplates are 3D printed flat on the build platform,
//  and hold everything else together
sideplate_origin=[25,74,reflector_forward-10];
sideplate_rotate=[0,0,6.0];

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


// The "space frame" holds the device on the head
module spaceframe() 
{
    support_x=-5;
    nheadpoints=3; // first 3 are on head
    nframepoints=5; // includes frame points
	// Support coords: x up, y eyedir, z toward center
    framepoints=[
        [support_x+5,-60,2], // back temple
        [support_x+5,-25,30], // low forehead
        [support_x+60,-58,30], // high forehead
        [support_x+10,10,0], // front glasses frame
        [support_x+focal_length-5,-25,0] // top diagonal brace
    ];
    
    $fn=6;
    dFrame=6;
    union()
    for (i=[nheadpoints:nframepoints-1])
    for (j=[0:i-1])
        hull() {
            translate(framepoints[i])
                sphere(d=dFrame);
            translate(framepoints[j])
                sphere(d=dFrame);
        }
    dHead=12;
    color([0.5,0.5,0.5])
    union()
    for (i=[1:nheadpoints-1])
    for (j=[0:i-1])
        hull() {
            translate(framepoints[i])
                sphere(d=dHead);
            translate(framepoints[j])
                sphere(d=dHead);
        }
}      

sideplate_wall_height=11;
// Outlines to hold parts to the sideplates
module sideplate_holders()
{
    walls=2.0;
    intersection() {
        sideplate_from_world()
        difference() {
            union() { // extra meat to hold parts in:
                reflector_outline(walls);
                phone_outline(walls);
                lens_frame(+1);
            }
        }
        // Trim sideplates to hold parts
        translate([100-10,0,+sideplate_wall_height/2])
            cube([200,200,sideplate_wall_height],center=true);
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
				// Baseplate outline: hull of functional parts
                scale([1,1,thinwall/sideplate_wall_height]) 
					hull() sideplate_holders();

                // Elliptical hole, to make part lighter
                translate([phone_above*0.4,20,0])
                    scale([2,1,1])
                        cylinder(d=40,h=20,center=true);
            }
			
			// Hold the lenses in place
			sideplate_from_world() {
				lens_ring();
				lens_frame(-1);
			}
            
            // "space frame" holds device to head
            spaceframe();
        }
        
        // Trim bottom flat
        translate([0,0,-100-0.001]) cube([200,200,200],center=true);
        
        // Space for actual parts
        sideplate_from_world()
            union() {
                reflector_outline();
                phone_outline();
                lens();
				
                niosh_outside(); // don't intersect the user's head
            }
    }
}

module printable_sideplates() {
    //symmetry()
    {
        translate([0,-38,0])
        rotate([0,0,-10])
        sideplate();
    }
}

module functional_parts() {
    symmetry() world_from_sideplate() sideplate();
    #union() {
        reflector_outline();
        phone_outline();
        lenses();
    }
    niosh_outside();
}


// Fix orientation of NIOSH head to standard printable
module niosh_to_standard() {
    color([0.8,0.7,0.5])
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
//printable_sideplates();


