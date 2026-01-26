package.path = "src/?.lua;" .. package.path
cad = require("cad")
shapes = require("shapes")

function create_hex_nut(params)
    -- Parameters & Defaults
    shaft_dia = params.shaft_dia or 6
    pitch = params.pitch or 1.0
    head_dia = params.head_dia or 12 -- Same as bolt head?
    head_height = params.head_height or 5
    fn_shaft = params.fn or 64

    -- 1. Nut Body (Hexagon)
    nut_body = cad.create("cylinder", {
        r = head_dia / 2,
        h = head_height,
        fn = 6,
        center = true
    })

    -- 2. Core Hole (Major Diameter)
    -- We start with a hole of the Major Diameter.
    -- Then we ADD the thread ridges back in.
    hole = cad.create("cylinder", {
        r = shaft_dia / 2,
        h = head_height + 2, -- Thru hole
        fn = fn_shaft,
        center = true
    })

    -- 3. Internal Thread (Ridge)
    -- We use the same 'cutter' geometry as the bolt (cut=true).
    -- This geometry represents the "Groove" of the bolt.
    -- In the nut, this "Groove" volume becomes the "Ridge" volume.
    -- Geometry: Base at R (surface), Tip at R-depth (inward).
    
    thread_depth = params.thread_depth or 0.6
    tool_fn_val = params.tool_fn or 12
    
    profile_params = {
        depth = thread_depth,
        crest_width = params.thread_crest_width or 0.1,
        root_width = params.thread_root_width or 1.6,
        tool_func = function(d, cw, rw)
             c = cad.create("cylinder", {
                h = d + 1.0, 
                r1 = cw / 2, 
                r2 = rw / 2, 
                fn = tool_fn_val,
                center = true
            })
            c = cad.transform("rotate", c, {0, 90, 0})
            return c
        end
    }

    t = shapes.thread(shaft_dia / 2, head_height, pitch, fn_shaft, true, profile_params)
    
    -- Align thread (Center it)
    -- shapes.thread generates from Z=0 to h. Center is h/2.
    -- We want center at 0.
    t = cad.transform("translate", t, {0, 0, -head_height/2})
    
    -- 4. CSG Operations
    -- Nut = (Body - Hole) + Thread
    nut_shell = cad.boolean("difference", {nut_body, hole})
    raw_nut = cad.boolean("union", {nut_shell, t})
    
    -- 5. Cleanup / Flush Cut
    -- Cut away anything protruding Z > head_height/2 or Z < -head_height/2
    cut_h = head_height -- arbitrary large height for cutter
    cut_r = head_dia * 2 -- arbitrary large radius
    
    top_cutter = cad.create("cylinder", {r=cut_r, h=cut_h, fn=32, center=true})
    top_cutter = cad.transform("translate", top_cutter, {0, 0, head_height/2 + cut_h/2})
    
    bot_cutter = cad.create("cylinder", {r=cut_r, h=cut_h, fn=32, center=true})
    bot_cutter = cad.transform("translate", bot_cutter, {0, 0, -head_height/2 - cut_h/2})
    
    final_nut = cad.boolean("difference", {raw_nut, top_cutter, bot_cutter})
    
    return final_nut
end

-- Allow usage as a module
if package.loaded.import_mode == true then
    return create_hex_nut
end

params = {
    shaft_dia = 6,
    pitch = 1.0,
    head_dia = 12,
    head_height = 5,
    fn = 64,
    thread_depth = 0.6,
    thread_root_width = 1.6,
    thread_crest_width = 0.1,
    tool_fn = 12
}

print("Generating Hex Nut...")
nut = create_hex_nut(params)
print("Exporting...")
cad.export(nut, "out/hex_nut.stl")
print("Done: out/hex_nut.stl")
