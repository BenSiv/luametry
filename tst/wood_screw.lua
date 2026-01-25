package.path = "src/?.lua;" .. package.path
cad = require("cad")
shapes = require("shapes")

function create_wood_screw(params)
    -- Parameters
    head_dia = params.head_dia or 10  
    head_height = params.head_height or 4
    shaft_dia = params.shaft_dia or 5
    length = params.length or 20
    fn_shaft = params.fn or 64
    tip_length = params.tip_length or 5
    
    -- Head: Hexagon
    head = cad.create("cylinder", {
        r = head_dia / 2, 
        h = head_height, 
        fn = 6,
        center = true
    })
    
    -- Shaft
    shaft_len = length - tip_length
    shaft = cad.create("cylinder", {
        r = shaft_dia / 2, 
        h = shaft_len, 
        fn = fn_shaft,
        center = true
    })
    
    -- Pointed Tip
    tip = cad.create("cylinder", {
        r1 = 0.01,
        r2 = shaft_dia / 2,
        h = tip_length,
        fn = fn_shaft,
        center = true
    })
    
    -- Align parts
    head = cad.transform("translate", head, {0, 0, head_height / 2})
    shaft = cad.transform("translate", shaft, {0, 0, -shaft_len / 2})
    tip = cad.transform("translate", tip, {0, 0, -shaft_len - tip_length/2})
    
    -- Thread parameters
    pitch = params.pitch or 1.5
    tool_fn_val = params.tool_fn or 6
    fade_len = params.fade_length or 8
    
    -- Common tool function
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
    
    -- 1. TIP THREAD: Tapered to follow cone
    tip_thread_len = tip_length + 2
    profile_tip = {
        depth = params.thread_depth,
        crest_width = params.thread_crest_width,
        root_width = params.thread_root_width,
        radius_taper = {
            bottom = {
                start_r = 0.01,
                end_r = shaft_dia / 2,
                start_z = 0,
                end_z = tip_length
            }
        },
        tool_func = tool_func_common
    }
    t_tip = shapes.thread(shaft_dia / 2, tip_thread_len, pitch, fn_shaft, false, profile_tip)
    t_tip = cad.transform("translate", t_tip, {0, 0, -shaft_len - tip_length + tip_thread_len/2})
    
    -- 2. MAIN THREAD: No taper, constant radius on shaft
    main_thread_len = shaft_len - fade_len - 5
    profile_main = {
        depth = params.thread_depth,
        crest_width = params.thread_crest_width,
        root_width = params.thread_root_width,
        tool_func = tool_func_common
    }
    t_main = shapes.thread(shaft_dia / 2, main_thread_len, pitch, fn_shaft, false, profile_main)
    t_main = cad.transform("translate", t_main, {0, 0, -(shaft_len - fade_len - 5) / 2})
    
    -- 3. TOP THREAD: Fade out near head
    top_thread_len = fade_len + 2
    profile_top = {
        depth = params.thread_depth,
        crest_width = params.thread_crest_width,
        root_width = params.thread_root_width,
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
    t_top = cad.transform("translate", t_top, {0, 0, top_thread_len/2 - 2})
    
    -- Combine everything
    threaded_shaft = cad.boolean("union", {shaft, t_tip, t_main, t_top, tip})
    screw = cad.boolean("union", {head, threaded_shaft})
    
    return screw
end

-- Parameters
params = {
    head_dia = 12,
    head_height = 5,
    shaft_dia = 6,
    length = 30,
    tip_length = 5,
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
