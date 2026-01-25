package.path = "src/?.lua;" .. package.path
cad = require("cad")

function create_screwdriver(params)
    -- Parameters
    handle_dia = params.handle_dia or 20
    handle_len = params.handle_len or 80
    shaft_dia = params.shaft_dia or 6
    shaft_len = params.shaft_len or 100
    tip_len = params.tip_len or 10 -- Length of the Phillips cut
    
    -- 1. Handle: Cylinder with 4 flutes (cutouts)
    handle_base = cad.create("cylinder", {
        r = handle_dia / 2,
        h = handle_len,
        fn = 32,
        center = true
    })
    
    -- Flutes: Cylinders subtracted from handle surface
    flute_dia = handle_dia * 0.4
    flute = cad.create("cylinder", {
        r = flute_dia / 2,
        h = handle_len + 1,
        fn = 32,
        center = true
    })
    
    -- Position flutes
    -- Offset from center > handle radius
    offset = handle_dia / 2
    f1 = cad.transform("translate", flute, {offset, 0, 0})
    f2 = cad.transform("translate", flute, {-offset, 0, 0})
    f3 = cad.transform("translate", flute, {0, offset, 0})
    f4 = cad.transform("translate", flute, {0, -offset, 0})
    
    cutters = cad.boolean("union", {f1, f2, f3, f4})
    handle = cad.boolean("difference", {handle_base, cutters})
    
    -- 2. Shaft: Cylinder
    shaft = cad.create("cylinder", {
        r = shaft_dia / 2,
        h = shaft_len,
        fn = 32,
        center = true
    })
    
    -- 3. Tip: Phillips Head Logic
    -- User spec: "the head would be cut out of the shaft using 4 cubes in an angle"
    -- Shaft tip is cylinder.
    -- We want to create a cross shape that tapers.
    -- Subtractive method: Cut away material to leave the cross.
    -- We need 4 cutting planes (cubes) angled to form the V-grooves of the Phillips.
    
    -- Phillips shape: 4 fins.
    -- Between fins are V-shaped valleys.
    -- We cut 4 V-valleys.
    -- Each valley is formed by a cutter (cube/wedge).
    -- Angled relative to shaft axis (to taper).
    
    cutter_w = shaft_dia * 2 -- Wide enough to cut whole side
    cutter_t = shaft_dia * 0.8 -- Thickness of cut
    cutter_h = tip_len * 2
    
    wedge = cad.create("cube", {cutter_w, cutter_t, cutter_h, center=true})
    
    -- Angle the wedge to create taper
    -- Rotate around X axis?
    -- Tip taper angle ~ 30 deg?
    angle = 15 -- degrees
    
    -- We want to cut the "corners" to leave a cross.
    -- If we have a cylinder. And we cut 4 "corners" (inter-fin spaces).
    -- Cutters should be at 45 deg angles (between fins).
    
    -- Cutter positioning logic:
    -- Place wedge at 45 deg position.
    -- Tilt it to taper.
    
    -- Actually, simpler:
    -- Create 4 wedges uniformly distributed (0, 90, 180, 270).
    -- Tilt them inward to cut the valleys.
    
    -- Wedge geometry: Tapered cut?
    -- Using a cube, rotated.
    
    -- Let's try:
    -- 1. Create a "Valley Cutter".
    -- 2. Rotate it 45 deg (between axis).
    -- 3. Tilt it away from center axis so it cuts deeper at tip? Or deeper at base?
    -- Phillips tapers to point. So cuts are deeper at tip.
    -- Actually, user said: "cut out of the square... additional 4 squares... in 45 degree angle"
    -- Here shaft is Cylinder.
    -- "head would be cut out of the shaft using 4 cubes in an angle"
    
    -- Let's define one cube cutter.
    c = cad.create("cube", {shaft_dia, shaft_dia, tip_len*2, center=true})
    
    -- Rotate cube 45 deg around Z (to align with diagonal)
    -- Then Rotate around Y (to taper)
    
    -- Better approach:
    -- 4 Cubes.
    -- Each cube removes one quadrant between the fins.
    -- Cube needs to come in at angle.
    
    fin_thick = 1.0 -- Thickness of the cross fin at tip
    
    -- Cutter removes material.
    -- Let's assume shaft is aligned Z. Tip is at +Z end of shaft.
    -- We want to leave a Cross.
    
    -- Cutter 1 (Top-Right quadrant):
    -- Cube rotated 45 deg Z.
    -- Rotated 15 deg Y?
    
    -- Let's implement based on "4 cubes in an angle".
    -- Create cube.
    cube = cad.create("cube", {shaft_dia, shaft_dia, tip_len*3, center=true})
    
    -- Rotate 45 deg Z (Diamond profile)
    -- This diamond aligns with the "valleys" of the cross (Valleys are diagonal to fins).
    -- Wait. Fins are typically + and x.
    -- If fins are Axis Aligned (+), Valleys are Diagonal (x).
    -- So cutter should be aligned on Diagonal.
    
    -- So:
    -- Cut 1: At 45 deg.
    -- Cut 2: At 135 deg.
    -- Cut 3: At 225 deg.
    -- Cut 4: At 315 deg.
    
    -- Each cut is an angled plane removing the material between fins.
    -- Angle: The "Taper".
    
    -- Cutter shape: Just a large block.
    -- We tilt it to form the taper.
    taper_angle = 20
    
    -- Offset from center determines fin thickness.
    offset = 0.8 -- Roughly fin thickness/2?
    
    -- We need 4 cuts.
    cutters = {}
    for i=0,3 do
        -- Base Cube
        cut = cad.create("cube", {shaft_dia*2, shaft_dia*2, tip_len*2, center=true})
        
        -- Move out to offset
        cut = cad.transform("translate", cut, {shaft_dia, 0, 0})
        
        -- Rotate to taper (Tilt inward/outward)
        -- We want to cut the TIP (smaller dim) more than base?
        -- Tapered shaft: Tip is small.
        -- So we cut MORE at tip.
        -- Tilt "inward" at top.
        cut = cad.transform("rotate", cut, {0, -taper_angle, 0})
        
        -- Rotate to quadrant position
        angle_z = 45 + (i * 90)
        cut = cad.transform("rotate", cut, {0, 0, angle_z})
        
        table.insert(cutters, cut)
    end
    
    tip_cutters = cad.boolean("union", cutters)
    
    -- Apply cuts to Shaft TIP
    -- Shaft tip is at z = shaft_len/2.
    -- Move cutters to tip.
    tip_cutters = cad.transform("translate", tip_cutters, {0, 0, shaft_len/2})
    
    shaft_tip = cad.boolean("difference", {shaft, tip_cutters})
    
    
    -- Align Handle and Shaft
    -- Handle ends at handle_len/2. Shaft starts at -shaft_len/2.
    -- But both centered.
    -- Move shaft up.
    shaft_tip = cad.transform("translate", shaft_tip, {0, 0, handle_len/2 + shaft_len/2})
    
    driver = cad.boolean("union", {handle, shaft_tip})
    return driver
end

params = {
    handle_dia = 25,
    handle_len = 80,
    shaft_dia = 6,
    shaft_len = 100,
    tip_len = 10
}

print("Generating Screwdriver...")
driver = create_screwdriver(params)
print("Exporting...")
cad.export(driver, "out/screwdriver.stl")
print("Done: out/screwdriver.stl")
