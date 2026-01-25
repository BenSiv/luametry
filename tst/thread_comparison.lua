package.path = "src/?.lua;" .. package.path
cad = require("cad")
shapes = require("shapes")

-- Utils for timing
function time_it(name, func)
    start = os.clock()
    res = func()
    duration = os.clock() - start
    print(string.format("%s: %.4f seconds", name, duration))
    return res, duration
end

-- Common Parameters
params = {
    radius = 5,
    pitch = 2.0,
    length = 20,
    fn = 64
}

---------------------------------------------------------
-- Method 1: Legacy Stacking (Union of many small cutters)
---------------------------------------------------------
function make_thread_stacking()
    -- Simplified version of shapes.thread logic
    r = params.radius
    h = params.length
    p = params.pitch
    fn = params.fn
    
    cutters = {}
    turns = h / p
    step_angle = 360 / fn
    total_steps = math.ceil(turns * fn)
    step_z = h / total_steps
    
    -- Create single cutter shape (cone-ish)
    cutter_base = cad.create("cylinder", {
        h = p * 0.8, r1 = 0.1, r2 = p * 0.6, fn = 6, center=true
    })
    cutter_base = cad.transform("rotate", cutter_base, {0, 90, 0}) -- Point along X
    
    -- Central cylinder
    cyl = cad.create("cylinder", {r=r, h=h, fn=fn, center=true})
    
    for i = 0, total_steps do
        angle = i * step_angle
        z = (i * step_z) - (h/2)
        
        -- Position cutter
        c = cad.transform("translate", cutter_base, {r, 0, 0})
        c = cad.transform("rotate", c, {0, 0, angle})
        c = cad.transform("translate", c, {0, 0, z})
        
        table.insert(cutters, c)
    end
    
    -- Subtract all cutters from cylinder
    cutters_union = cad.union_batch(cutters)
    return cad.boolean("difference", {cyl, cutters_union})
end

---------------------------------------------------------
-- Method 2: Extrude with Twist
---------------------------------------------------------
function make_thread_extrude()
    r = params.radius
    h = params.length
    p = params.pitch
    fn = params.fn
    
    -- Create profile for a single thread turn
    -- A triangle pointing inward (subtractive look) or outward (additive)
    -- Let's make it additive for simplicity (a coil around a cylinder)
    
    -- Profile in XZ plane (which becomes XY for extrude, then Z is length)
    -- Actually cad.extrude takes 2D points.
    -- X corresponds to radial distance, Y corresponds to thread profile width?
    -- No, extrude lifts a 2D shape up Z.
    -- To make a horizontal thread, we extrude a profile that represents the cross section of the screw,
    -- but usually extrude goes straight up. 
    -- With linear twist, it makes a screw.
    
    -- We extrude a shape that represents the "thread tooth" + core
    -- Star shape? No, that makes a multi-start thread depending on shape.
    -- If we want a single start thread, the profile must be asymmetrical?
    -- Wait, linear extrude with twist rotates the whole shape.
    -- If the shape is a circle off-center, it makes a coil (spring).
    -- If the shape is a central circle + a tooth, it makes a screw.
    
    core_r = r - (p * 0.3)
    outer_r = r
    
    points = {}
    
    -- Generate "gear" like profile which when twisted becomes threads
    -- Note: Standard linear extrusion with twist makes multi-start threads equivalent to number of teeth.
    -- A single tooth profile twisted 360 deg over 1 pitch length = single start.
    
    -- Let's define one tooth pointing right
    tooth_w_deg = 20 -- Width of tooth in degrees
    
    -- Circle part
    for i = 0, fn do
        a = (i / fn) * 360
        rad = math.rad(a)
        curr_r = core_r
        
        -- Add a tooth bump at angle 0
        -- Simple bump logic
        if a < tooth_w_deg or a > (360 - tooth_w_deg) then
            curr_r = outer_r
        end
        
        table.insert(points, {
            math.cos(rad) * curr_r,
            math.sin(rad) * curr_r
        })
    end
    
    total_twist = (h / p) * 360
    
    return cad.extrude(points, h, {
        twist = total_twist,
        slices = math.ceil((h/p) * fn) 
    })
end

---------------------------------------------------------
-- Method 3: Revolve + Warp (True Helix)
---------------------------------------------------------
function make_thread_revolve_warp()
    r = params.radius
    p = params.pitch
    h = params.length
    
    -- 1. Create the Cross Section Profile (in X-Y plane, where X is radius)
    -- We revolving around Z? Manifold revolve usually revolves around Z or Y?
    -- Standard manifold revolve is around Z.
    
    -- Profile: A triangle for the thread tooth
    depth = p * 0.6
    pts = {
        {r - depth, -p/2}, -- Bottom inner
        {r, 0},            -- Peak
        {r - depth, p/2},  -- Top inner
        {r - depth, -p/2}  -- Close loop
    }
    
    -- 2. Revolve it into a ring (donut)
    -- But we want a long cylinder? No, we revolve the long way?
    -- No, we create a stack of rings?
    -- Or we create ONE ring and warp it?
    -- Actually, to make a long screw, we might want to revolve a 
    -- profile that is the FULL length? No, that's just a cylinder.
    
    -- To make a helix with Warp:
    -- Method A: Create a long cylinder with many segments, then warp vertex positions?
    -- Method B: Revolve a small profile approx 360 deg * turns?
    -- Manifold's revolve takes "degrees". If we pass 360*10, does it make overlapping geometry?
    -- Yes, likely overlapping.
    
    -- Valid approach for Warp:
    -- 1. Create a "Stack of disks" or just a very segmented cylinder via Revolve?
    --    Actually, standard Revolve of a profile offset from center creates a torus.
    --    Manifold revolve allows > 360 degrees? The C++ docs say "revolve_degrees".
    --    If we revolve > 360, it self-intersects unless we move it in Z simultaneously.
    --    But Revolve doesn't move in Z.
    
    -- Revised Approach:
    -- 1. Extrude a profile (the thread cross section) to make a long straight bar.
    --    Length corresponds to the helical length?
    --    No, that's "bending".
    
    -- Correct Warp Approach for Helix:
    -- 1. Start with a shape that represents the UNROLLED thread.
    --    A long prism (extrumed triangle).
    --    Length L = sqrt((2*pi*r)^2 + p^2) * turns ??
    --    Warp maps (x,y,z) -> (new_x, new_y, new_z)
    --    Map linear X coordinate to Angle?
    
    -- Let's try the "Revolve" approach assuming we warp AFTER.
    -- If we make a simple Torus (360 deg), and warp it to separate the ends in Z?
    -- That makes one turn.
    -- We can union multiple turns.
    
    -- BETTER:
    -- Use the warp function to transform a flat pattern into a helix.
    -- Input: A flat "comb" or "rack" gear shape.
    -- Warp: Bend the rack into a cylinder. X -> Angle.
    
    -- Let's generate a "Rack" (linear thread profile)
    -- Length = Circumference * Turns? No.
    -- Length = Circumference.
    -- We can warp a plane into a cylinder.
    
    num_turns = h / p
    circumference = 2 * math.pi * r
    
    -- Create a "Rack" corresponding to the thread profile extruded along Y?
    -- We want the final result to be along Z.
    -- Mapping:
    -- X (input) -> Angle (output)
    -- Y (input) -> Z (output)
    -- Z (input) -> Radius (output)
    
    -- 1. Create one tooth profile
    -- Triangle in YZ plane?
    -- Let's stick to standard extrude.
    -- Extrude a triangle (thread cross-section) along X.
    -- Length of extrusion = circumference * num_turns?
    -- That would be a huge straight bar.
    -- Then we wrap it around the cylinder.
    
    -- Profile (Triangle)
    points = {
        {0, -p/2},
        {p*0.6, 0}, -- Depth
        {0, p/2}
    }
    -- Align to make it a "tooth" standing up Z?
    -- Let's say Input X is the "Length around cylinder".
    
    total_len = circumference * num_turns
    
    -- Extrude the tooth along X (length)
    -- The profile is in YZ plane? cad.extrude takes "points" (2D). Usually XY.
    -- Let's make profile in XY, extrude Z (width of rack). 
    -- Then rotate/translate to align.
    
    tooth_poly = {
        {-p/2, 0},           -- Bottom
        {0, p*0.6},          -- Peak
        {p/2, 0},            -- Top
        {-p/2, 0}            -- Close
    }
    
    -- Extrude to create the long generic bar
    -- Note: We need high segmentation along the length to allow smooth bending
    -- cad.extrude doesn't have "segments along height" parameter exposed in my basic wrapper?
    -- Wait, looking at cad.lua:
    -- return csg.extrude(points, height, slices, twist, scale_x, scale_y)
    -- 'slices' is the segmentation along Z!
    
    segs_per_turn = 64
    total_slices = math.ceil(segs_per_turn * num_turns)
    
    rack = cad.extrude(tooth_poly, total_len, {
        slices = total_slices
    })
    
    -- Now Rack is along Z axis. Profile in XY.
    -- We want Length to map to Angle.
    -- Current Length is Z.
    -- Input Z -> Output Angle.
    -- Input Y -> Output Z (Pitch rise). -- Wait, the rack itself is straight.
    
    -- Warp Function:
    -- Wraps the Z-axis-aligned bar around a cylinder of radius r.
    -- And applies the pitch rise.
    
    -- But the rack is straight. If we just wrap it, it forms a ring (or stack of rings).
    -- To make a helix, the Z coordinate of the rack needs to map to BOTH Angle and Z?
    -- No.
    -- If we have a straight rack, and we wrap it:
    -- Z_in becomes Angle theta = Z_in / r.
    -- X_in, Y_in become offset from circle?
    
    -- Standard Helix Warp:
    -- x' = (r + x) * cos(z * k)
    -- y' = (r + x) * sin(z * k)
    -- z' = z ? No, that's just a twisted bar (like method 2).
    
    -- We want the "Bar" to be wound around the cylinder.
    -- So Z_in (length) -> Angle around cylinder.
    -- And we need to add a "Slope" to Z_out based on Angle to make it climb.
    
    -- Let's try this:
    -- Start with the Rack along Z.
    -- Radius derived from X?
    
    -- Warp Function definition
    function helix_warper(x, y, z)
        -- Map Input Z to Angle
        -- z ranges from 0 to total_len (circumference * turns)
        angle = z / r -- radians
        
        -- Map Input Z to Height (Pitch rise)
        -- We want z_out to increase by pitch every 2*pi*r length
        -- slope = pitch / (2*pi*r)
        z_slope = p / (2 * math.pi * r)
        z_climb = z * z_slope
        
        -- Radial offset comes from Y (height of tooth)
        -- Base radius = r
        -- y goes from 0 to depth
        current_r = r + y
        
        -- X is width of tooth (pitch direction)? 
        -- In our extrusion:
        -- Profile was in XY. Extrusion along Z.
        -- Poly: {-p/2, 0} to {p/2, 0}. This is X width.
        -- So X represents the "Axial" width of the thread.
        -- When wrapped, X direction should map to Z direction of cylinder.
        
        new_x = current_r * math.cos(angle)
        new_y = current_r * math.sin(angle)
        new_z = z_climb + x -- Add the profile width to the climbing Z
        
        return new_x, new_y, new_z
    end
    
    -- Orient the rack correctly before warping?
    -- Currently created along Z.
    -- Our warp assumes Z is the long axis. Correct.
    -- Profile:
    -- X in profile -> Z in output (width of thread). Correct.
    -- Y in profile -> Radius in output (height of tooth). Correct.
    
    return cad.warp(rack, helix_warper)
end

---------------------------------------------------------
-- Execution
---------------------------------------------------------
print("=== Thread Generation Comparison ===")
print("Params: Radius="..params.radius..", Pitch="..params.pitch..", Length="..params.length)

-- 1. Stacking
print("\n--- Stacking Method ---")
s1 = make_thread_stacking()
start = os.clock()
cad.export(s1, "out/thread_stacking.stl")
duration = os.clock() - start
print(string.format("Generation+Export Time: %.4f seconds", duration))

-- 2. Extrude Twist
print("\n--- Extrude-Twist Method ---")
s2 = make_thread_extrude()
start = os.clock()
cad.export(s2, "out/thread_extrude_twist.stl")
duration = os.clock() - start
print(string.format("Generation+Export Time: %.4f seconds", duration))

-- 3. Revolve Warp
print("\n--- Revolve-Warp Method ---")
s3 = make_thread_revolve_warp()
start = os.clock()
cad.export(s3, "out/thread_revolve_warp.stl")
duration = os.clock() - start
print(string.format("Generation+Export Time: %.4f seconds", duration))

print("\nDone.")
