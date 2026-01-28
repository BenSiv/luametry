package.path = package.path .. ";./src/?.lua"
cad = require("cad")

-- Create default cylinder h=10
-- If base-aligned: Z is 0..10
-- If centered: Z is -5..5
c = cad.create.cylinder({h=10, r=1})

-- Probe at Z=-2 (Size 1) -> Covers -2.5 to -1.5? No cube size 1 center true -> -0.5 to 0.5
-- Translate probe to -2
probe = cad.create.cube({size=1, center=true})
probe = cad.modify.translate(probe, {0,0,-2})

int = cad.combine.intersection({c, probe})
v = cad.query.volume(int)

print("Intersection Volume at Z=-2: " .. v)

if v > 0 then
    print("Result: Cylinder extends below Z=0 (Likely CENTERED)")
else
    print("Result: Cylinder starts at Z=0 (Likely BASE-ALIGNED)")
end
