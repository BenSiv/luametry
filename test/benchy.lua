
package.path = package.path .. ";./src/?.lua"
cad = require("cad")

print("Modeling 3DBenchy from official dimensions...")

-- Official 3DBenchy Dimensions (from 3dbenchy.com):
-- Overall: 60mm long, 31mm wide, 48mm tall
-- Chimney: inner 3mm, outer 7mm, depth 11mm
-- Bridge roof: 23mm long, 5.5° slope
-- Cargo box: 12x10.81mm outer, 8x7mm inner, 9mm deep
-- Rear window: 9mm inner diameter
-- Front window: 10.5x9.5mm
-- Bow overhang: 40° angle
-- Cargo box top: 15.5mm above bottom

-- 1. HULL
-- Approximate hull as flattened sphere shaped by bow cuts
hull_base = cad.create("sphere", {r=30, fn=64})
-- Scale to approximately 60x31x25 (before deck/cabin add height)
hull_base = cad.transform("scale", hull_base, {1.0, 0.52, 0.42})

-- Flatten bottom (Z=0 is bottom)
bottom_cut = cad.create("cube", {size={100, 100, 50}, center=true})
bottom_cut = cad.transform("translate", bottom_cut, {0, 0, -25})
hull = cad.difference({hull_base, bottom_cut})

-- Bow cuts for 40° overhang
-- Using cylinders to carve the characteristic bow shape
cutter_r = 35
bow_cut_l = cad.create("cylinder", {h=100, r=cutter_r, fn=64})
bow_cut_l = cad.transform("translate", bow_cut_l, {30, 32, 0})
bow_cut_r = cad.create("cylinder", {h=100, r=cutter_r, fn=64})
bow_cut_r = cad.transform("translate", bow_cut_r, {30, -32, 0})
hull = cad.difference({hull, bow_cut_l, bow_cut_r})

-- Interior hollow for cockpit
inner_hull = cad.create("sphere", {r=26, fn=64})
inner_hull = cad.transform("scale", inner_hull, {0.85, 0.45, 0.35})
inner_hull = cad.transform("translate", inner_hull, {-3, 0, 6})
hull = cad.difference({hull, inner_hull})

-- 2. DECK
deck = cad.create("cube", {size={50, 26, 2}, center=true})
deck = cad.transform("translate", deck, {-2, 0, 5})
hull_group = cad.union({hull, deck})

-- 3. CABIN (Bridge)
-- Cabin sits at roughly Z=6 to Z=28 (22mm tall)
cabin_l = 22
cabin_w = 18
cabin_h = 22
cabin = cad.create("cube", {size={cabin_l, cabin_w, cabin_h}, center=true})
cabin = cad.transform("translate", cabin, {-8, 0, 17})

-- Bridge roof: 23mm long, slopes 5.5°
roof = cad.create("cube", {size={23, cabin_w+2, 2}, center=true})
roof = cad.transform("translate", roof, {-8, 0, 28.5})

-- Front window (10.5 x 9.5mm)
front_window = cad.create("cube", {size={5, 10.5, 9.5}, center=true})
front_window = cad.transform("translate", front_window, {4, 0, 20})

-- Rear window (9mm inner diameter circle)
rear_window = cad.create("cylinder", {h=10, r=4.5, fn=32})
rear_window = cad.transform("rotate", rear_window, {0, 90, 0})
rear_window = cad.transform("translate", rear_window, {-20, 0, 20})

-- Side door arches (approximate)
function create_arch(w, d, h)
    r = w/2
    hc = h - r
    cube_part = cad.create("cube", {size={w, d, hc}, center=true})
    cube_part = cad.transform("translate", cube_part, {0, 0, hc/2})
    cyl_part = cad.create("cylinder", {h=d, r=r, center=true})
    cyl_part = cad.transform("rotate", cyl_part, {90, 0, 0})
    cyl_part = cad.transform("translate", cyl_part, {0, 0, hc})
    return cad.union({cube_part, cyl_part})
end

door_cut = create_arch(8, 25, 14)
door_cut = cad.transform("translate", door_cut, {-8, 0, 6})

cabin = cad.difference({cabin, front_window, rear_window, door_cut})

-- 4. CHIMNEY
-- Inner 3mm, outer 7mm diameter, 11mm deep hole
chimney_outer = cad.create("cylinder", {h=15, r=3.5, fn=32})
chimney_inner = cad.create("cylinder", {h=11, r=1.5, fn=32})
chimney_inner = cad.transform("translate", chimney_inner, {0, 0, 4}) -- Blind hole
chimney = cad.difference({chimney_outer, chimney_inner})
chimney = cad.transform("translate", chimney, {10, 0, 6})

-- 5. CARGO BOX (Stern)
-- 12x10.81mm outer, 8x7mm inner, 9mm deep
-- Top at 15.5mm above bottom
box_outer = cad.create("cube", {size={12, 10.81, 9}, center=true})
box_inner = cad.create("cube", {size={8, 7, 11}, center=true})
box_inner = cad.transform("translate", box_inner, {0, 0, 2})
cargo_box = cad.difference({box_outer, box_inner})
cargo_box = cad.transform("translate", cargo_box, {-22, 0, 11}) -- Top at 15.5

-- 6. HAWSEPIPE (bow hole, 4mm diameter)
hawse = cad.create("cylinder", {h=15, r=2, fn=32})
hawse = cad.transform("rotate", hawse, {0, 90, 0})
hawse = cad.transform("translate", hawse, {28, 0, 6})
hull_group = cad.difference({hull_group, hawse})

-- FINAL ASSEMBLY
benchy = cad.union({hull_group, cabin, roof, chimney, cargo_box})

print("Exporting 3DBenchy...")
if cad.export(benchy, "output/benchy.stl") then
    print("Success: output/benchy.stl")
else
    print("Failure")
end
