package.path = "src/?.lua;" .. package.path
cad = require("cad")
shapes = require("shapes")

function create_bolt(params)
    -- Parameters
    head_dia = params.head_dia or 10  
    head_height = params.head_height or 4
    shaft_dia = params.shaft_dia or 5
    length = params.length or 20
    fn_shaft = params.fn or 64
    
    -- Head: Hexagon is a cylinder with fn=6
    head = cad.create.cylinder( {
        r = head_dia / 2, 
        h = head_height, 
        fn = 6,
        center = true
    })
    
    -- Shaft
    shaft = cad.create.cylinder( {
        r = shaft_dia / 2, 
        h = length, 
        fn = fn_shaft,
        center = true
    })
    
    -- Align parts
    head = cad.modify.translate( head, {0, 0, head_height / 2})
    shaft = cad.modify.translate( shaft, {0, 0, -length / 2})
    
    -- Thread
    -- M6 coarse pitch is 1mm.
    pitch = params.pitch or 1.0
    thread_len = length - 5 -- Partial threading
    
    -- Thread Profile Overrides
    tool_fn_val = params.tool_fn or 6
    profile_params = {
        depth = params.thread_depth,
        crest_width = params.thread_crest_width,
        root_width = params.thread_root_width,
        -- Custom Tool Definition: 60-degreeish cone
        tool_func = function(d, cw, rw)
             c = cad.create.cylinder( {
                h = d + 1.0, 
                r1 = cw / 2, -- Tip
                r2 = rw / 2, -- Base
                fn = tool_fn_val,
                center = true
            })
            -- Orient along X
            c = cad.modify.rotate( c, {0, 90, 0})
            return c
        end
    }
    
    -- Pass 'true' for cut parameter (unused in new func but kept for compatibility?)
    -- machined_thread(params)
    t = shapes.thread({
        r = shaft_dia / 2, 
        h = thread_len, 
        pitch = pitch, 
        fn = fn_shaft, 
        cut = true, 
        depth = profile_params.depth,
        crest_width = profile_params.crest_width,
        root_width = profile_params.root_width
    })
    
    -- Align thread with shaft
    t = cad.modify.translate( t, {0, 0, -length})
    
    -- Subtract thread from shaft
    threaded_shaft = cad.combine.difference( {shaft, t})
    
    bolt = cad.combine.union( {head, threaded_shaft})
    
    return bolt
end

-- Allow usage as a module
if package.loaded.import_mode == true then
    return create_bolt
end

-- Default Parameters
-- Parameters (Edit these to change the model)
params = {
    head_dia = 12,
    head_height = 5,
    shaft_dia = 6,
    length = 30,
    pitch = 1.0,
    fn = 64,
    -- Optional thread profile overrides
    -- Defines the "Cone" cutter shape
    thread_depth = 0.6,      -- Cone Height (depth of cut) - ~20% of shaft radius
    thread_root_width = 1.6, -- Cone Base Width (at surface)
    thread_crest_width = 0.1, -- Cone Tip Width (small for nearly sharp point)
    tool_fn = 12              -- Cone Resolution (6 = hexagonal, 32 = smooth)
}

print("Generating Hex Bolt with params:")
for k, v in pairs(params) do print("  " .. k .. ": " .. v) end

bolt = create_bolt(params)

-- print("Exporting...")
-- cad.export(bolt, "out/hex_bolt.stl")
-- print("Done: out/hex_bolt.stl")

return bolt
