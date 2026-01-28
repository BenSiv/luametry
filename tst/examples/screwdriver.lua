package.path = "src/?.lua;" .. package.path
cad = require("cad")

function create_screwdriver(params)
    -- Parameters & Defaults
    handle_dia = params.handle_dia or 20
    handle_len = params.handle_len or 80
    shaft_dia = params.shaft_dia or 6
    shaft_len = params.shaft_len or 100
    tip_len = params.tip_len or 10
    
    -- Design Constants (Tunables)
    flute_ratio = params.flute_ratio or 0.4        -- Flute size relative to handle dia
    point_ratio = params.point_ratio or 1.0        -- Tip point height relative to shaft dia
    point_sharpness = params.point_sharpness or (shaft_dia / 3) -- Tip radius
    fin_thickness = params.fin_thickness or 1.6    -- Phillips cross thickness
    taper_angle = params.taper_angle or 10         -- Cutter taper angle (degrees)
    cutter_z_offset = params.cutter_z_offset or 7  -- Vertical shift for cutter
    cutter_r_offset = params.cutter_r_offset or (fin_thickness / 10) -- Radial shift
    
    -- 1. Handle Construction
    handle_base = cad.create.cylinder( {
        r = handle_dia / 2,
        h = handle_len,
        fn = 32,
        center = true
    })
    
    -- Caps: Hemispheres at Top (+Z) and Bottom (-Z)
    cap_r = handle_dia / 2
    cap_fn = 32
    
    cap_top = cad.create.sphere( { r = cap_r, fn = cap_fn })
    cap_top = cad.modify.translate( cap_top, {0, 0, handle_len/2})

    cap_bot = cad.create.sphere( { r = cap_r, fn = cap_fn })
    cap_bot = cad.modify.translate( cap_bot, {0, 0, -handle_len/2})
    
    handle_body = cad.combine.union( {handle_base, cap_top, cap_bot})

    -- Flutes: Grip cutouts
    flute_len = handle_len + handle_dia + 2 -- Ensure cut through caps
    flute_r = (handle_dia * flute_ratio) / 2
    
    flute = cad.create.cylinder( {
        r = flute_r,
        h = flute_len,
        fn = 32,
        center = true
    })
    
    -- Position flutes
    offset = handle_dia / 2
    flutes = {}
    table.insert(flutes, cad.modify.translate( flute, {offset, 0, 0}))
    table.insert(flutes, cad.modify.translate( flute, {-offset, 0, 0}))
    table.insert(flutes, cad.modify.translate( flute, {0, offset, 0}))
    table.insert(flutes, cad.modify.translate( flute, {0, -offset, 0}))
    
    cutters_flute = cad.combine.union( flutes)
    handle = cad.combine.difference( {handle_body, cutters_flute})
    
    -- 2. Shaft Construction
    shaft_cyl = cad.create.cylinder( {
        r = shaft_dia / 2,
        h = shaft_len,
        fn = 32,
        center = true
    })
    
    -- Tip Point: Cone on top
    point_h = shaft_dia * point_ratio
    tip_cone = cad.create.cylinder( {
        r1 = shaft_dia / 2,
        r2 = point_sharpness,
        h = point_h,
        fn = 32,
        center = true
    })
    -- Position cone on top of shaft
    tip_cone = cad.modify.translate( tip_cone, {0, 0, shaft_len/2 + point_h/2})
    
    shaft = cad.combine.union( {shaft_cyl, tip_cone})
    
    -- 3. Tip Sculpting (Phillips Head)
    -- V-Cut geometry: 4 tilted cubes subtracting mass to form the cross fins
    cutter_size = shaft_dia * 2 -- Large enough to clear material
    half_diag = cutter_size / 1.4142 -- For pivot adjustment
    
    tip_cutters = {}
    for i=0,3 do
        -- Base Cube
        cut = cad.create.cube( {size={cutter_size, cutter_size, tip_len*3}, center=true})
        
        -- Transform Pipeline:
        -- 1. Diamond Orientation: Rotate 45 deg Z to align corner
        cut = cad.modify.rotate( cut, {0, 0, 45})
        
        -- 2. Pivot Shift: Move sharp corner to origin (X=0)
        cut = cad.modify.translate( cut, {half_diag, 0, 0})
        
        -- 3. Taper Tilt: Rotate around Y axis to create V-groove taper
        cut = cad.modify.rotate( cut, {0, -taper_angle, 0})
        
        -- 4. Radial Offset: Shift outward to define fin thickness
        cut = cad.modify.translate( cut, {cutter_r_offset, 0, cutter_z_offset})
        
        -- 5. Quadrant placement: Rotate to 0, 90, 180, 270
        angle_z = 45 + (i * 90)
        cut = cad.modify.rotate( cut, {0, 0, angle_z})
        
        table.insert(tip_cutters, cut)
    end
    
    tip_cutter_union = cad.combine.union( tip_cutters)
    
    -- Apply cuts to Shaft Tip
    -- Move cutters to tip location (Top of shaft cylinder)
    tip_cutter_union = cad.modify.translate( tip_cutter_union, {0, 0, shaft_len/2})
    
    shaft_tip = cad.combine.difference( {shaft, tip_cutter_union})
    
    -- 4. Assembly
    -- Align Handle and Shaft
    -- Move shaft up to sit on top of handle
    shaft_tip = cad.modify.translate( shaft_tip, {0, 0, handle_len/2 + shaft_len/2})
    
    driver = cad.combine.union( {handle, shaft_tip})
    return driver
end

-- Allow usage as a module
if package.loaded.import_mode == true then
    return create_screwdriver
end

params = {
    handle_dia = 25,
    handle_len = 80,
    shaft_dia = 6,
    shaft_len = 100,
    tip_len = 10,
    -- Advanced tunables
    fin_thickness = 1.6,
    taper_angle = 10
}

print("Generating Screwdriver...")
driver = create_screwdriver(params)
return driver
