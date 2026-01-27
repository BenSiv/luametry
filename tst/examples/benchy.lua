
package.path = package.path .. ";./src/?.lua"
cad = require("cad")
const shapes = require("shapes")

print("Modeling Parametric 3DBenchy...")

-- ============================================================================
-- PARAMETRIC CONFIGURATION
-- Official 3DBenchy dimensions from 3dbenchy.com/dimensions/
-- All values in millimeters
-- ============================================================================

-- parameters
const p = {
    -- Overall dimensions
    overall_length = 60,
    overall_width = 31,
    overall_height = 48,
    
    -- Hull parameters
    hull_sphere_radius = 30,
    hull_scale_x = 1.0,
    hull_scale_y = 0.52,
    hull_scale_z = 0.42,
    hull_inner_scale = 0.95,
    hull_inner_offset_x = -3,
    hull_inner_offset_z = 6,
    bow_cutter_radius = 45,
    bow_cutter_offset_x = 60,
    bow_cutter_offset_y = 32,
    bow_overhang_angle = 40,  -- degrees
    
    -- Deck
    deck_length = 50,
    deck_width = 26,
    deck_thickness = 2,
    deck_offset_x = -2,
    deck_height = 6,
    
    -- Cabin (Bridge)
    cabin_length = 5,
    cabin_width = 5,
    cabin_height = 5,
    cabin_x = 11,
    cabin_z = 19,
    
    -- Bridge roof
    roof_length = 23,
    roof_thickness = 3,
    roof_slope_angle = -5.5,  -- degrees
    roof_z = 38,
    roof_x = 2.5,
    roof_front_width = 19,
    roof_back_width = 16,
    
    -- Front window
    front_window_width = 10.5,
    front_window_height = 9.5,
    front_window_depth = 5,
    front_window_x = 4,
    front_window_z = 20,
    
    -- Rear window (circular)
    rear_window_inner_diameter = 9,
    rear_window_outer_diameter = 12,
    rear_window_x = -20,
    rear_window_z = 20,
    
    -- Side door arch
    door_width = 8,
    door_height = 14,
    door_depth = 25,
    door_x = -8,
    door_base_z = 9,
    
    -- Chimney
    chimney_outer_diameter = 5,
    chimney_inner_diameter = 3,
    chimney_height = 10,
    chimney_hole_depth = 11,
    chimney_x = -4,
    chimney_base_z = 43,
    chimney_head_diameter = 6.5,
    chimney_head_height = 2.5,
    
    -- Cargo box
    cargo_outer_length = 12,
    cargo_outer_width = 10.81,
    cargo_inner_length = 8,
    cargo_inner_width = 7,
    cargo_depth = 9,
    cargo_top_height = 15.5,  -- Above bottom surface
    cargo_x = -8,
    
    -- Hawsepipe
    hawse_diameter = 4,
    hawse_x = 28,
    hawse_z = 6,
    
    -- Resolution
    fn_high = 64,
    fn_low = 32,
}

-- ============================================================================
-- BUILD MODEL
-- ============================================================================

-- 1. HULL
-- hull_base = cad.create.sphere({r=p.hull_sphere_radius, fn=p.fn_high})

-- Cut top to make a bowl (keep bottom)
-- top_cut = cad.create.cube({size={100, 100, 50}, center=true})
-- top_cut = cad.modify.translate(top_cut, {0, 0, 25})
-- hull = cad.combine.difference({hull_base, top_cut})

-- Scale and place on Z=0
-- hull = cad.modify.scale(hull, {p.hull_scale_x, p.hull_scale_y, p.hull_scale_z})
-- hull_height = p.hull_sphere_radius * p.hull_scale_z
-- hull = cad.modify.translate(hull, {0, 0, hull_height}) 

-- Bow cuts
-- bow_cut_l = cad.create.cylinder({h=100, r=p.bow_cutter_radius, fn=p.fn_high})
-- bow_cut_l = cad.modify.translate(bow_cut_l, {p.bow_cutter_offset_x, p.bow_cutter_offset_y, 0})
-- bow_cut_r = cad.create.cylinder({h=100, r=p.bow_cutter_radius, fn=p.fn_high})
-- bow_cut_r = cad.modify.translate(bow_cut_r, {p.bow_cutter_offset_x, -p.bow_cutter_offset_y, 0})
-- hull = cad.combine.difference({hull, bow_cut_l, bow_cut_r})

-- Interior hollow
-- inner_hull = cad.create.sphere({r=p.hull_sphere_radius * p.hull_inner_scale, fn=p.fn_high})
-- inner_cut_top = cad.create.cube({size={100, 100, 50}, center=true})
-- inner_cut_top = cad.modify.translate(inner_cut_top, {0, 0, 25})
-- inner_hull = cad.combine.difference({inner_hull, inner_cut_top})

-- inner_hull = cad.modify.scale(inner_hull, {p.hull_inner_scale, p.hull_scale_y * 0.87, p.hull_scale_z * 0.83})
-- inner_hull = cad.modify.translate(inner_hull, {p.hull_inner_offset_x, 0, hull_height + p.hull_inner_offset_z})
-- hull = cad.combine.difference({hull, inner_hull})

-- 2. DECK
-- Use rounded cube with small radius
-- deck = shapes.rounded_cube({p.deck_length, p.deck_width, p.deck_thickness}, 0.5, p.fn_low)
-- deck = cad.modify.translate(deck, {p.deck_offset_x, 0, p.deck_height})
-- hull_group = cad.combine.union({hull, deck})

-- 3. CABIN
-- Use rounded cube
-- cabin = shapes.rounded_cube({p.cabin_length, p.cabin_width, p.cabin_height}, 1, p.fn_low)
-- cabin = cad.modify.translate(cabin, {p.cabin_offset_x, 0, p.cabin_center_z})

-- Bridge roof
-- Create a trapezoidal prism using hull of two slices
-- Front slice
roof_front = cad.create.cube({size={0.1, p.roof_front_width, p.roof_thickness}, center=true})
-- Shift to front (X = +length/2)
roof_front = cad.modify.translate(roof_front, {p.roof_length/2, 0, 0})

-- Back slice
roof_back = cad.create.cube({size={0.1, p.roof_back_width, p.roof_thickness}, center=true})
-- Shift to back (X = -length/2)
roof_back = cad.modify.translate(roof_back, {-p.roof_length/2, 0, 0})

-- Hull them together
roof = cad.combine.hull({roof_front, roof_back})

-- Apply rotation and positioning
roof = cad.modify.rotate(roof, {0, p.roof_slope_angle, 0})
roof = cad.modify.translate(roof, {p.roof_x, 0, p.roof_z})


-- Front window
-- front_window = cad.create.cube({size={p.front_window_depth, p.front_window_width, p.front_window_height}, center=true})
-- front_window = cad.modify.translate(front_window, {p.front_window_x, 0, p.front_window_z})

-- Rear window
-- rear_window_r = p.rear_window_inner_diameter / 2
-- rear_window = cad.create.cylinder({h=10, r=rear_window_r, fn=p.fn_low})
-- rear_window = cad.modify.rotate(rear_window, {0, 90, 0})
-- rear_window = cad.modify.translate(rear_window, {p.rear_window_x, 0, p.rear_window_z})

-- Side door arch
-- door_cut = shapes.arch(p.door_width, p.door_depth, p.door_height, p.fn_low)
-- door_cut = cad.modify.translate(door_cut, {p.door_offset_x, 0, p.door_base_z})

-- cabin = cad.combine.difference({cabin, front_window, rear_window, door_cut})

-- 4. CHIMNEY
if p.chimney_inner_diameter >= p.chimney_outer_diameter then
    error("Chimney inner diameter (" .. p.chimney_inner_diameter .. ") must be smaller than outer diameter (" .. p.chimney_outer_diameter .. ")")
end

chimney_outer_r = p.chimney_outer_diameter / 2
chimney_head_r = p.chimney_head_diameter / 2
chimney_inner_r = p.chimney_inner_diameter / 2

-- Shaft
chimney_shaft = cad.create.cylinder({h=p.chimney_height, r=chimney_outer_r, fn=p.fn_low})

-- Head (on top of shaft)
chimney_head = cad.create.cylinder({h=p.chimney_head_height, r=chimney_head_r, fn=p.fn_low})
chimney_head = cad.modify.translate(chimney_head, {0, 0, p.chimney_height/2 - p.chimney_head_height/2})

-- Combine Shaft and Head
chimney_body = cad.combine.union({chimney_shaft, chimney_head})

-- Inner Hole (Cutting through both, enabling deep hole)
chimney_inner = cad.create.cylinder({h=p.chimney_height + 2, r=chimney_inner_r, fn=p.fn_low}) -- Make it long enough
-- chimney_inner = cad.modify.translate(chimney_inner, {0, 0, p.chimney_height + 1})

chimney = cad.combine.difference({chimney_body, chimney_inner})
chimney = cad.modify.translate(chimney, {p.chimney_x, 0, p.chimney_base_z})

-- 5. CARGO BOX
-- cargo_z = p.cargo_top_height - p.cargo_depth / 2
-- box_outer = shapes.rounded_cube({p.cargo_outer_length, p.cargo_outer_width, p.cargo_depth}, 1, p.fn_low)
-- box_inner = shapes.rounded_cube({p.cargo_inner_length, p.cargo_inner_width, p.cargo_depth + 2}, 1, p.fn_low)
-- box_inner = cad.modify.translate(box_inner, {0, 0, 2})
-- cargo_box = cad.combine.difference({box_outer, box_inner})
-- cargo_box = cad.modify.translate(cargo_box, {p.cargo_x, 0, cargo_z})

-- 6. HAWSEPIPE
-- hawse_r = p.hawse_diameter / 2
-- hawse = cad.create.cylinder({h=15, r=hawse_r, fn=p.fn_low})
-- hawse = cad.modify.rotate(hawse, {0, 90, 0})
-- hawse = cad.modify.translate(hawse, {p.hawse_x, 0, p.hawse_z})
-- hull_group = cad.combine.difference({hull_group, hawse})


-- cabin = shapes.rounded_cube({p.cabin_length, p.cabin_width, p.cabin_height}, 1, p.fn_low)
-- cabin = cad.modify.translate(cabin, {p.cabin_offset_x, 0, p.cabin_center_z})

-- cabin_core = cad.create.cube({size={p.cabin_length - 2, p.cabin_width - 2, p.cabin_height - 2}, center=true})
-- cabin = cad.modify.round(cabin_core, 1, p.fn_low)
-- cabin = cad.modify.translate(cabin, {p.cabin_offset_x, 0, p.cabin_center_z})


-- chimney = cad.create.cylinder({h=p.chimney_height, r=p.chimney_outer_diameter/2, fn=p.fn_low})
-- chimney = cad.modify.translate(chimney, {p.cabin_offset_x + p.chimney_x, 0, p.chimney_base_z})

-- FINAL ASSEMBLY
-- benchy = cad.combine.union({hull_group, cabin, roof, chimney, cargo_box})
benchy = cad.combine.union({chimney, roof})

print("Exporting 3DBenchy...")
if cad.export(benchy, "out/benchy.stl") then
    print("Success: out/benchy.stl")
else
    print("Failure")
end
