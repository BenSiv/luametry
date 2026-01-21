
package.path = package.path .. ";./src/?.lua"
cad = require("cad")

print("Modeling High-Fidelity Benchy CSG...")

-- Function to create an Arch (Union of Cube and Cylinder)
function create_arch(w, d, h)
    -- w: width (x), d: depth (y), h: total height (z)
    -- Cylinder radius is w/2
    r = w/2
    hc = h - r -- Height of the cube part
    
    cube_part = cad.create("cube", {size={w, d, hc}, center=true})
    -- Move cube up so bottom is at 0? No, center=true means z is at 0.
    -- Let's make bottom at 0 for easier placement.
    cube_part = cad.transform("translate", cube_part, {0, 0, hc/2})
    
    cyl_part = cad.create("cylinder", {h=d, r=r, center=true})
    -- Cylinder is along Z by default. We need it along Y.
    cyl_part = cad.transform("rotate", cyl_part, {90, 0, 0})
    cyl_part = cad.transform("translate", cyl_part, {0, 0, hc})
    
    return cad.union({cube_part, cyl_part})
end

-- 1. THE HULL
-- Main Volume: Flattened Sphere
-- Benchy is roughly 60mm long, 30mm wide.
hull_base = cad.create("sphere", {r=30, fn=100})
hull_base = cad.transform("scale", hull_base, {1.0, 0.5, 0.5}) -- 60x30x30?
-- Flatten bottom: Cut off the bottom half + some
-- Current sphere is centered at 0,0,0. Z ranges -15 to +15.
-- We want a flat bottom. Let's slice everything below Z=-5?
bottom_cut = cad.create("cube", {size={100, 100, 50}, center=true})
bottom_cut = cad.transform("translate", bottom_cut, {0, 0, -30}) -- Top at -5
hull_flat = cad.difference({hull_base, bottom_cut})

-- The Bow Cuts
-- Two large cylinders/spheres to pinch the front (positive X)
-- Actually, the sphere shape is already round. The text says "angled inward to carve".
-- Let's use large cylinders on the sides to taper the bow more sharply than a sphere.
cutter_r = 50
bow_cut_left = cad.create("cylinder", {h=100, r=cutter_r, fn=64})
bow_cut_left = cad.transform("translate", bow_cut_left, {30, 45, 0}) 

bow_cut_right = cad.create("cylinder", {h=100, r=cutter_r, fn=64})
bow_cut_right = cad.transform("translate", bow_cut_right, {30, -45, 0})

hull_shaped = cad.difference({hull_flat, bow_cut_left, bow_cut_right})

-- Interior Hollow (Cockpit)
-- Smaller scaled version of the hull, shifted up/back
inner_hull = cad.transform("scale", hull_base, {0.85, 0.85, 0.85})
inner_hull = cad.transform("translate", inner_hull, {-2, 0, 5})
hull_shell = cad.difference({hull_shaped, inner_hull})

-- Gunwales (Rim)
-- The "shell" operation naturally creates gunwales if we just cut the "inside".
-- But we need the deck to be solid.

-- 2. DECK
-- Flat surface inside the shell
deck = cad.create("cube", {size={55, 25, 2}, center=true})
deck = cad.transform("translate", deck, {0, 0, 0}) -- Adjust Z to sit inside

hull_group = cad.union({hull_shell, deck})

-- 3. CABIN
-- Box on rear half
cabin_w = 20
cabin_l = 25
cabin_h = 22
cabin_box = cad.create("cube", {size={cabin_l, cabin_w, cabin_h}, center=true})
-- Place it
cabin_box = cad.transform("translate", cabin_box, {-5, 0, 11 + 2}) -- On top of deck (z~2?)

-- Roof
roof_plate = cad.create("cube", {size={cabin_l+4, cabin_w+2, 2}, center=true})
roof_plate = cad.transform("translate", roof_plate, {-5, 0, 11 + 2 + 11 + 1}) -- On top of cabin

-- Arch Cutouts (Side Windows/Doors)
door_cut = create_arch(10, 30, 15) -- w=10, depth=30 (punch through), height=15
door_cut = cad.transform("translate", door_cut, {-5, 0, 2}) -- Adjust Z base

-- Front Window
window_front = cad.create("cube", {size={5, 12, 8}, center=true})
window_front = cad.transform("translate", window_front, {8, 0, 18})

-- Rear Window (Circle)
window_rear = cad.create("cylinder", {h=10, r=4, fn=32})
window_rear = cad.transform("rotate", window_rear, {0, 90, 0}) -- Along X
window_rear = cad.transform("translate", window_rear, {-18, 0, 18})

cabin_final = cad.difference({cabin_box, door_cut, window_front, window_rear})

-- 4. CHIMNEY
-- Tapered cylinder
chimney = cad.create("cylinder", {h=12, r1=3, r2=4, fn=32})
-- Hollow it
chimney_hole = cad.create("cylinder", {h=15, r=2, fn=32})
chimney = cad.difference({chimney, chimney_hole})
chimney = cad.transform("translate", chimney, {12, 0, 15}) -- In front of cabin

-- 5. STERN BOX
stern_box = cad.create("cube", {size={8, 12, 5}, center=true})
stern_box = cad.transform("translate", stern_box, {-22, 0, 5})
-- Hollow
stern_void = cad.create("cube", {size={6, 10, 6}, center=true})
stern_void = cad.transform("translate", stern_void, {-22, 0, 7})
stern_box = cad.difference({stern_box, stern_void})

-- 6. ASSEMBLY
benchy = cad.union({hull_group, cabin_final, roof_plate, chimney, stern_box})

print("Exporting Benchy...")
if cad.export(benchy, "output/benchy.stl") then
    print("Success: output/benchy.stl")
else
    print("Failure")
end
