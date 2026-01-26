package.path = "src/?.lua;" .. package.path
cad = require("cad")
shapes = require("shapes")

function create_wood_screw(params)
    -- Parameters & Defaults
    head_dia = params.head_dia or 10  
    head_height = params.head_height or 4
    shaft_dia = params.shaft_dia or 5
    length = params.length or 20
    fn_shaft = params.fn or 64
    tip_length = params.tip_length or 5
    
    -- Design Tunables
    cone_ratio = params.cone_ratio or 0.7  -- Head cone portion
    cyl_ratio = params.cyl_ratio or 0.3    -- Head cylinder portion
    tip_sharpness = params.tip_sharpness or 0.01
    
    -- Thread Parameters
    pitch = params.pitch or 1.5
    tool_fn_val = params.tool_fn or 6
    fade_len = params.fade_length or 8
    thread_depth = params.thread_depth
    thread_crest_width = params.thread_crest_width
    thread_root_width = params.thread_root_width
    
    -- Helper Function for Thread Tool
    tool_func_common = function(d, cw, rw)
        c = cad.create("cylinder", {
            h = d + 1.0,
            r1 = rw / 2,
            r2 = cw / 2,
            fn = tool_fn_val,
            center = true
        })
        c = cad.transform("rotate", c, {0, 90, 0})
        return c
    end

    -- 1. Head Construction (Composite Cone + Cylinder)
    cone_height = head_height * cone_ratio
    cyl_height = head_height * cyl_ratio
    
    head_cone = cad.create("cylinder", {
        r1 = shaft_dia / 2,     -- Bottom matches shaft
        r2 = head_dia / 2,      -- Top matches head
        h = cone_height,
        fn = 32,
        center = true
    })
    
    head_cyl = cad.create("cylinder", {
        r = head_dia / 2,
        h = cyl_height,
        fn = 32,
        center = true
    })
    
    -- Align Head Parts
    head_cone = cad.transform("translate", head_cone, {0, 0, cone_height/2})
    head_cyl = cad.transform("translate", head_cyl, {0, 0, cone_height + cyl_height/2})
    
    head_solid = cad.boolean("union", {head_cone, head_cyl})
    
    -- 2. Recess Cut (Screwdriver Tip)
    -- Load screwdriver generator safely
    package.loaded.import_mode = true
    create_driver = dofile("tst/screwdriver.lua")
    package.loaded.import_mode = nil
    
    -- Driver Dimensions (For Subtracting Recess)
    driver_params = {
        handle_dia = 10, 
        handle_len = 10, 
        shaft_dia = 6,   -- Standard #2 Phillips approx
        shaft_len = 50,
        tip_len = 10
    }
    driver = create_driver(driver_params)
    
    -- Calculate positioning for driver
    d_handle = driver_params.handle_dia
    d_shaft = driver_params.shaft_len
    d_shaft_dia = driver_params.shaft_dia
    d_point_h = d_shaft_dia * 1.0 -- implicit default from screwdriver.lua
    
    -- Tip Z Position relative to Driver Center
    tip_z = (d_handle / 2) + d_shaft + d_point_h
    
    -- Invert Driver (Tip Down)
    driver = cad.transform("rotate", driver, {180, 0, 0})
    
    -- Position Driver to penetrate Head
    head_top_z = cone_height + cyl_height
    sink = head_height * 0.6 -- Penetration depth
    
    driver = cad.transform("translate", driver, {0, 0, head_top_z + tip_z - sink})
    
    -- Cut Recess
    head = cad.boolean("difference", {head_solid, driver})
    
    -- 3. Shaft & Tip Construction
    shaft_len = length - tip_length
    shaft = cad.create("cylinder", {
        r = shaft_dia / 2, 
        h = shaft_len, 
        fn = fn_shaft,
        center = true
    })
    
    tip = cad.create("cylinder", {
        r1 = tip_sharpness,
        r2 = shaft_dia / 2,
        h = tip_length,
        fn = fn_shaft,
        center = true
    })
    
    -- Align Shaft Parts
    shaft = cad.transform("translate", shaft, {0, 0, -shaft_len / 2})
    tip = cad.transform("translate", tip, {0, 0, -shaft_len - tip_length/2})
    
    -- 4. Thread Generation
    
    -- A. Tip Thread (Tapered)
    tip_thread_len = tip_length
    profile_tip = {
        depth = thread_depth,
        crest_width = thread_crest_width,
        root_width = thread_root_width,
        radius_taper = {
            bottom = {
                start_r = tip_sharpness,
                end_r = shaft_dia / 2,
                start_z = 0,
                end_z = tip_length
            }
        },
        tool_func = tool_func_common
    }
    t_tip = shapes.thread(shaft_dia / 2, tip_thread_len, pitch, fn_shaft, false, profile_tip)
    t_tip = cad.transform("translate", t_tip, {0, 0, -shaft_len - tip_length})
    t_tip = cad.transform("rotate", t_tip, {0, 0, 120}) -- Phase match
    
    -- B. Main Thread (Constant)
    main_thread_len = shaft_len - fade_len
    profile_main = {
        depth = thread_depth,
        crest_width = thread_crest_width,
        root_width = thread_root_width,
        tool_func = tool_func_common
    }
    t_main = shapes.thread(shaft_dia / 2, main_thread_len, pitch, fn_shaft, false, profile_main)
    t_main = cad.transform("translate", t_main, {0, 0, -shaft_len})
    
    -- C. Top Thread (Fade Out)
    top_thread_len = fade_len
    profile_top = {
        depth = thread_depth,
        crest_width = thread_crest_width,
        root_width = thread_root_width,
        radius_taper = {
            top = {
                start_r = shaft_dia / 2,
                end_r = shaft_dia / 4,
                start_z = 0,
                end_z = fade_len
            }
        },
        tool_func = tool_func_common
    }
    t_top = shapes.thread(shaft_dia / 2, top_thread_len, pitch, fn_shaft, false, profile_top)
    t_top = cad.transform("translate", t_top, {0, 0, -top_thread_len})
    
    -- 5. Assembly
    threaded_shaft = cad.boolean("union", {shaft, t_tip, t_main, t_top, tip})
    screw = cad.boolean("union", {head, threaded_shaft, tip})
    
    return screw
end

-- Parameters
params = {
    head_dia = 5,
    head_height = 2,
    shaft_dia = 3,
    length = 30,
    tip_length = 10,
    fade_length = 8,
    pitch = 1.5,
    fn = 64,
    thread_depth = 0.4,
    thread_root_width = 0.8,
    thread_crest_width = 0.1,
    tool_fn = 12
}

print("Generating Wood Screw with params:")
for k, v in pairs(params) do print("  " .. k .. ": " .. v) end

screw = create_wood_screw(params)

print("Exporting...")
cad.export(screw, "out/wood_screw.stl")
print("Done: out/wood_screw.stl")
