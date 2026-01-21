
package.path = package.path .. ";./src/?.lua"
cad = require("cad")

print("Modeling Benchy CSG...")

-- Main Hull (approximated with squashed spheres/cylinders)
-- Lower Hull
hull_main = cad.create("cube", {size={60, 30, 15}, center=true})
-- Shape the hull bow
bow_cut = cad.create("sphere", {r=30, fn=64})
bow_cut = cad.transform("translate", bow_cut, {30, 0, 15})
-- hull_main = cad.intersection({hull_main, bow_cut}) -- Too aggressive
-- Let's stick to simple blocky benchy for "low poly" style first

-- Deck
deck = cad.create("cube", {size={55, 28, 5}, center=true})
deck = cad.transform("translate", deck, {0, 0, 8})

-- Cabin
cabin = cad.create("cube", {size={25, 20, 20}, center=true})
cabin = cad.transform("translate", cabin, {-5, 0, 20})

-- Roof
roof = cad.create("cube", {size={28, 22, 2}, center=true})
roof = cad.transform("translate", roof, {-5, 0, 31})

-- Pillars
p1 = cad.create("cylinder", {h=20, r=1.5, center=true})
p1 = cad.transform("translate", p1, {-15, 8, 20})
p2 = cad.create("cylinder", {h=20, r=1.5, center=true})
p2 = cad.transform("translate", p2, {-15, -8, 20})
p3 = cad.create("cylinder", {h=20, r=1.5, center=true})
p3 = cad.transform("translate", p3, {5, 8, 20})
p4 = cad.create("cylinder", {h=20, r=1.5, center=true})
p4 = cad.transform("translate", p4, {5, -8, 20})

-- Chimney
chimney = cad.create("cylinder", {h=15, r=3, center=true})
chimney = cad.transform("translate", chimney, {-10, 0, 35})

-- Cargo Box
box = cad.create("cube", {size={10, 15, 8}, center=true})
box = cad.transform("translate", box, {10, 0, 12})
-- Hollow it out
box_void = cad.create("cube", {size={8, 13, 10}, center=true})
box_void = cad.transform("translate", box_void, {10, 0, 14})
box_final = cad.difference({box, box_void})

-- Combine basics
benchy = cad.union({hull_main, deck, roof, p1, p2, p3, p4, chimney, box_final})

-- Cuts/Windows
win_side = cad.create("cube", {size={10, 30, 8}, center=true})
win_side = cad.transform("translate", win_side, {-5, 0, 22})

win_front = cad.create("cube", {size={10, 15, 8}, center=true})
win_front = cad.transform("translate", win_front, {10, 0, 22})

door_back = cad.create("cube", {size={5, 10, 15}, center=true})
door_back = cad.transform("translate", door_back, {-18, 0, 18})

benchy = cad.difference({benchy, win_side, win_front, door_back})


if cad.export(benchy, "output/benchy.stl") then
    print("Benchy generated at output/benchy.stl")
else
    print("Failed to generate Benchy")
end
