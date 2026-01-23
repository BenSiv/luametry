
package.path = package.path .. ";./src/?.lua"
cad = require("cad")

print("Modeling Parametric 3DBenchy...")

-- ============================================================================
-- PARAMETRIC CONFIGURATION
-- Official 3DBenchy dimensions from 3dbenchy.com/dimensions/
-- All values in millimeters
-- ============================================================================

const PARAMS = {
    -- Overall dimensions
    overall_length = 60,
    overall_width = 31,
    overall_height = 48,
    
    -- Hull parameters
    hull_sphere_radius = 30,
    hull_scale_x = 1.0,
    hull_scale_y = 0.52,
    hull_scale_z = 0.42,
    hull_inner_scale = 0.85,
    hull_inner_offset_x = -3,
    hull_inner_offset_z = 6,
    bow_cutter_radius = 35,
    bow_cutter_offset_x = 30,
    bow_cutter_offset_y = 32,
    bow_overhang_angle = 40,  -- degrees
    
    -- Deck
    deck_length = 50,
    deck_width = 26,
    deck_thickness = 2,
    deck_offset_x = -2,
    deck_height = 5,
    
    -- Cabin (Bridge)
    cabin_length = 22,
    cabin_width = 18,
    cabin_height = 22,
    cabin_offset_x = -8,
    cabin_center_z = 17,
    
    -- Bridge roof
    roof_length = 23,
    roof_thickness = 2,
    roof_slope_angle = 5.5,  -- degrees
    roof_height = 28.5,
    
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
    door_offset_x = -8,
    door_base_z = 6,
    
    -- Chimney
    chimney_outer_diameter = 7,
    chimney_inner_diameter = 3,
    chimney_height = 15,
    chimney_hole_depth = 11,
    chimney_x = 10,
    chimney_base_z = 6,
    
    -- Cargo box
    cargo_outer_length = 12,
    cargo_outer_width = 10.81,
    cargo_inner_length = 8,
    cargo_inner_width = 7,
    cargo_depth = 9,
    cargo_top_height = 15.5,  -- Above bottom surface
    cargo_x = -22,
    
    -- Hawsepipe
    hawse_diameter = 4,
    hawse_x = 28,
    hawse_z = 6,
    
    -- Resolution
    fn_high = 64,
    fn_low = 32,
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function create_arch(w, d, h, fn)
    r = w / 2
    hc = h - r
    cube_part = cad.create("cube", {size={w, d, hc}, center=true})
    cube_part = cad.transform("translate", cube_part, {0, 0, hc/2})
    cyl_part = cad.create("cylinder", {h=d, r=r, fn=fn, center=true})
    cyl_part = cad.transform("rotate", cyl_part, {90, 0, 0})
    cyl_part = cad.transform("translate", cyl_part, {0, 0, hc})
    return cad.boolean("union", {cube_part, cyl_part})
end

-- ============================================================================
-- BUILD MODEL
-- ============================================================================

P = PARAMS  -- Shorthand

-- 1. HULL
hull_base = cad.create("sphere", {r=P.hull_sphere_radius, fn=P.fn_high})
hull_base = cad.transform("scale", hull_base, {P.hull_scale_x, P.hull_scale_y, P.hull_scale_z})

-- Flatten bottom
bottom_cut = cad.create("cube", {size={100, 100, 50}, center=true})
bottom_cut = cad.transform("translate", bottom_cut, {0, 0, -25})
hull = cad.boolean("difference", {hull_base, bottom_cut})

-- Bow cuts
bow_cut_l = cad.create("cylinder", {h=100, r=P.bow_cutter_radius, fn=P.fn_high})
bow_cut_l = cad.transform("translate", bow_cut_l, {P.bow_cutter_offset_x, P.bow_cutter_offset_y, 0})
bow_cut_r = cad.create("cylinder", {h=100, r=P.bow_cutter_radius, fn=P.fn_high})
bow_cut_r = cad.transform("translate", bow_cut_r, {P.bow_cutter_offset_x, -P.bow_cutter_offset_y, 0})
hull = cad.boolean("difference", {hull, bow_cut_l, bow_cut_r})

-- Interior hollow
inner_hull = cad.create("sphere", {r=P.hull_sphere_radius * P.hull_inner_scale, fn=P.fn_high})
inner_hull = cad.transform("scale", inner_hull, {P.hull_inner_scale, P.hull_scale_y * 0.87, P.hull_scale_z * 0.83})
inner_hull = cad.transform("translate", inner_hull, {P.hull_inner_offset_x, 0, P.hull_inner_offset_z})
hull = cad.boolean("difference", {hull, inner_hull})

-- 2. DECK
deck = cad.create("cube", {size={P.deck_length, P.deck_width, P.deck_thickness}, center=true})
deck = cad.transform("translate", deck, {P.deck_offset_x, 0, P.deck_height})
hull_group = cad.boolean("union", {hull, deck})

-- 3. CABIN
cabin = cad.create("cube", {size={P.cabin_length, P.cabin_width, P.cabin_height}, center=true})
cabin = cad.transform("translate", cabin, {P.cabin_offset_x, 0, P.cabin_center_z})

-- Bridge roof
roof = cad.create("cube", {size={P.roof_length, P.cabin_width + 2, P.roof_thickness}, center=true})
roof = cad.transform("translate", roof, {P.cabin_offset_x, 0, P.roof_height})

-- Front window
front_window = cad.create("cube", {size={P.front_window_depth, P.front_window_width, P.front_window_height}, center=true})
front_window = cad.transform("translate", front_window, {P.front_window_x, 0, P.front_window_z})

-- Rear window
rear_window_r = P.rear_window_inner_diameter / 2
rear_window = cad.create("cylinder", {h=10, r=rear_window_r, fn=P.fn_low})
rear_window = cad.transform("rotate", rear_window, {0, 90, 0})
rear_window = cad.transform("translate", rear_window, {P.rear_window_x, 0, P.rear_window_z})

-- Side door arch
door_cut = create_arch(P.door_width, P.door_depth, P.door_height, P.fn_low)
door_cut = cad.transform("translate", door_cut, {P.door_offset_x, 0, P.door_base_z})

cabin = cad.boolean("difference", {cabin, front_window, rear_window, door_cut})

-- 4. CHIMNEY
chimney_outer_r = P.chimney_outer_diameter / 2
chimney_inner_r = P.chimney_inner_diameter / 2
chimney_outer = cad.create("cylinder", {h=P.chimney_height, r=chimney_outer_r, fn=P.fn_low})
chimney_inner = cad.create("cylinder", {h=P.chimney_hole_depth, r=chimney_inner_r, fn=P.fn_low})
chimney_inner = cad.transform("translate", chimney_inner, {0, 0, P.chimney_height - P.chimney_hole_depth})
chimney = cad.boolean("difference", {chimney_outer, chimney_inner})
chimney = cad.transform("translate", chimney, {P.chimney_x, 0, P.chimney_base_z})

-- 5. CARGO BOX
cargo_z = P.cargo_top_height - P.cargo_depth / 2
box_outer = cad.create("cube", {size={P.cargo_outer_length, P.cargo_outer_width, P.cargo_depth}, center=true})
box_inner = cad.create("cube", {size={P.cargo_inner_length, P.cargo_inner_width, P.cargo_depth + 2}, center=true})
box_inner = cad.transform("translate", box_inner, {0, 0, 2})
cargo_box = cad.boolean("difference", {box_outer, box_inner})
cargo_box = cad.transform("translate", cargo_box, {P.cargo_x, 0, cargo_z})

-- 6. HAWSEPIPE
hawse_r = P.hawse_diameter / 2
hawse = cad.create("cylinder", {h=15, r=hawse_r, fn=P.fn_low})
hawse = cad.transform("rotate", hawse, {0, 90, 0})
hawse = cad.transform("translate", hawse, {P.hawse_x, 0, P.hawse_z})
hull_group = cad.boolean("difference", {hull_group, hawse})

-- FINAL ASSEMBLY
benchy = cad.boolean("union", {hull_group, cabin, roof, chimney, cargo_box})

print("Exporting 3DBenchy...")
if cad.export(benchy, "output/benchy.stl") then
    print("Success: output/benchy.stl")
else
    print("Failure")
end
