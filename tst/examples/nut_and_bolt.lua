package.path = "src/?.lua;" .. package.path
cad = require("cad")

-- Parameters common to both
params = {
    shaft_dia = 6,
    pitch = 1.0,
    -- Bolt
    bolt_len = 30,
    bolt_head_dia = 12,
    bolt_head_height = 5,
    -- Nut
    nut_head_dia = 12,
    nut_head_height = 5,
    -- Thread (Standard M6-ish)
    thread_depth = 0.6,
    thread_root_width = 1.6,
    thread_crest_width = 0.1,
    tool_fn = 12,
    fn = 64
}

-- Load Bolt Generator
package.loaded.import_mode = true
create_bolt = dofile("tst/examples/hex_bolt.lua")

-- Load Nut Generator
create_nut = dofile("tst/examples/hex_nut.lua")
package.loaded.import_mode = nil

print("Generating Bolt...")
bolt = create_bolt({
    head_dia = params.bolt_head_dia,
    head_height = params.bolt_head_height,
    shaft_dia = params.shaft_dia,
    length = params.bolt_len,
    pitch = params.pitch,
    fn = params.fn,
    thread_depth = params.thread_depth,
    thread_root_width = params.thread_root_width,
    thread_crest_width = params.thread_crest_width,
    tool_fn = params.tool_fn
})

print("Generating Nut...")
nut = create_nut({
    shaft_dia = params.shaft_dia,
    pitch = params.pitch,
    head_dia = params.nut_head_dia,
    head_height = params.nut_head_height,
    fn = params.fn,
    thread_depth = params.thread_depth,
    thread_root_width = params.thread_root_width,
    thread_crest_width = params.thread_crest_width,
    tool_fn = params.tool_fn
})

-- Position Nut on Bolt
-- Bolt head is at +Z (centered at `head_height/2`), Shaft down to -Z.
-- Bolt shaft starts at 0 and goes to -length.
-- Let's put the nut 10mm down the shaft.
-- Nut is centered at 0.
-- Move nut to Z = -15
nut_pos_z = -15
nut = cad.modify.translate( nut, {0, 0, nut_pos_z})

-- Rotate nut slightly for visual flair?
nut = cad.modify.rotate( nut, {0, 0, 30})

assembly = cad.combine.union( {bolt, nut})

return assembly