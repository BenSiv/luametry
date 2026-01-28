-- Luam supports 'const' for immutable variables
const cad = require("cad")
const shapes = require("shapes")

-- 1. Create Head
head = cad.create.cylinder({
    radius=5, 
    height=3, 
    segments=6, -- Hexagon
    center=true
})
-- Align head (move UP)
head = cad.modify.translate(head, {0, 0, 1.5})

-- 2. Create Shaft
shaft = cad.create.cylinder({
    radius=2.5,  -- 5mm diameter
    height=20,   -- 20mm length
    segments=32,
    center=true
})
-- Align shaft (move DOWN)
shaft = cad.modify.translate(shaft, {0, 0, -10})

-- 3. Create Thread (Cutter)
-- We set cut=true to generate a "negative" thread shape
thread_cutter = shapes.thread({
    radius=2.5, 
    height=15, 
    pitch=1.0, 
    segments=32,
    cut=true -- Subtractive mode
})
-- Align thread (move to bottom of shaft)
thread_cutter = cad.modify.translate(thread_cutter, {0, 0, -20})

-- 4. Apply Theading
-- Subtract the thread cutter from the shaft
threaded_shaft = cad.combine.difference({shaft, thread_cutter})

-- 5. Final Assembly
bolt = cad.combine.union({head, threaded_shaft})

return bolt