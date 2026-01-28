package.path = package.path .. ";./src/?.lua"
cad = require("cad")
const shapes = require("shapes")

print("Modeling Parametric 3DBenchy (Refactored)...")

-- ============================================================================
-- 1. UTILITIES
-- ============================================================================

-- Create a cylinder sitting on Z=0 (Base Aligned)
function base_cylinder(params)
    c = cad.create.cylinder(params)
    -- Default cylinder is centered (-h/2 to h/2). Move up by h/2.
    h = params.h or params.height
    return cad.modify.translate(c, {0, 0, h/2})
end

-- ============================================================================
-- 2. PARAMETERS
-- ============================================================================

const p = {
    -- Overall dimensions
    overall_length = 60,
    overall_width = 31,
    overall_height = 48,
    
    -- Hull parameters
    hull_stern_length = 33,
    hull_bow_length = 27,
    hull_width = 28,
    hull_lower_height = 8, -- Matches deck_z
    hull_upper_height = 14,
    hull_bow_width = 2, -- Tip width
    
    -- Deck
    deck_length = 50,
    deck_width = 26,
    deck_length = 50,
    deck_width = 26,
    deck_height = 2, -- Was thickness
    deck_x = -2,
    deck_z = 8, -- Was height (Location)
    
    -- Cabin (Bridge)
    cabin_length = 19,
    cabin_height = 30,
    cabin_x = 2,
    cabin_z = 9,
    cabin_front_width = 17,
    cabin_back_width = 14,
    cabin_front_width = 17,
    cabin_back_width = 14,
    cabin_front_slope = 5, -- degrees forward tilt
    cabin_wall_thickness = 2,
    
    -- Bridge roof
    roof_length = 22,
    roof_height = 3, -- Was thickness
    roof_z = 37.75, -- Was height (Location)
    roof_slope_angle = -5.5,  -- degrees
    roof_x = 2.5,
    roof_front_width = 19,
    roof_back_width = 16,
    
    -- Front window
    front_window_width = 10.5,
    front_window_height = 9.5,
    front_window_depth = 5,
    front_window_x = 10,
    front_window_z = 29.5,
    
    -- Rear window (circular)
    rear_window_inner_diameter = 9,
    rear_window_x = -20,
    rear_window_z = 27,
    
    -- Side door arch
    door_width = 9,
    door_height = 24,
    door_depth = 25,
    door_x = 0,
    door_z = 8, -- Was base_z (Location)
    
    -- Chimney
    chimney_outer_diameter = 5.0,
    chimney_inner_diameter = 3.0,
    chimney_head_diameter = 6.5,
    chimney_height = 7,
    chimney_hole_depth = 11,
    chimney_x = -4,
    chimney_head_height = 3,
    chimney_z = 38,
    
    -- Cargo box
    cargo_outer_length = 12,
    cargo_outer_width = 10.81,
    cargo_inner_length = 8,
    cargo_inner_width = 7,
    cargo_height = 9, -- Was cargo_depth
    cargo_z = 11, -- Sitting on deck (8) + offset? Or just above deck? Deck is 8. Box height 9.
    -- If sitting on deck, center Z should be deck_z + h/2 = 8 + 4.5 = 12.5?
    -- Let's just define Z location as the base of the box?
    -- No, "p.cargo_x/z" in assembly are Translations.
    -- If we build box at Origin, translation is the Center or Base?
    -- base_cylinder builds at Base.
    -- make_cabin built at Base.
    -- So let's align Cargo Box to Base Z=0 too.
    -- Then Z location = deck_z (8).
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
-- 3. DERIVED PARAMETERS (Calculated locations)
-- ============================================================================

function calculate_derived(p)
     -- Bounding boxes / Stack heights
     p.roof_base_z = p.deck_z + p.cabin_height
end

-- ============================================================================
-- 4. COMPONENTS
-- ============================================================================

function make_hull(p)
    -- 1. Lower Deck (Back / Stern)
    -- Simple box
    stern = cad.create.cube({size={p.hull_stern_length, p.hull_width, p.hull_lower_height}, center=true})
    -- Base aligned Z (move up by h/2)
    stern = cad.modify.translate(stern, {0, 0, p.hull_lower_height/2})
    -- Position X: Back half. Center is -bow_len/2? No.
    -- Let's say Origin (0,0) is center of boat? Or center of cabin?
    -- Cabin is at p.cabin_x (2).
    -- Lower deck goes from back_end to split_point.
    -- Upper deck goes from split_point to front_end.
    -- Let's define split_point relative to center?
    -- For simplicity, let's build them relative to each other and assume the join is at X=0 for now, then shift.
    -- NO, `separation of concerns` means we just make the shape.
    -- But the shape is complex (two parts).
    -- Let's make the JOIN at X=0.
    -- Stern: X from -stern_len to 0. Center at -stern_len/2.
    stern = cad.modify.translate(stern, {-p.hull_stern_length/2, 0, 0})
    
    -- 2. Upper Deck (Front / Bow)
    -- Tapered Prism (Trapezoid Hull)
    -- Back Slice (at X=0): Width = p.hull_width, Height = p.hull_upper_height
    -- Front Slice (at X=bow_len): Width = p.hull_bow_width, Height = p.hull_upper_height + curve?
    -- Let's keep height constant for now.
    
    slice_back = cad.create.cube({size={0.1, p.hull_width, p.hull_upper_height}, center=true})
    slice_back = cad.modify.translate(slice_back, {0, 0, p.hull_upper_height/2}) -- Base aligned
    
    slice_front = cad.create.cube({size={0.1, p.hull_bow_width, p.hull_upper_height}, center=true})
    slice_front = cad.modify.translate(slice_front, {p.hull_bow_length, 0, p.hull_upper_height/2}) -- Base aligned
    
    bow = cad.combine.hull({slice_back, slice_front})
    
    -- Union
    hull = cad.combine.union({stern, bow})
    
    -- 3. Hawsepipe (Cuts)
    -- Cylinders rotated 90 deg (Y axis) at the bow.
    -- Located at p.hawse_x, p.hawse_z.
    
    h_dia = p.hawse_diameter
    -- Cut needs to go through entire width. hull_width is 28. make it 40.
    h_len = p.hull_width + 10 
    
    cut = cad.create.cylinder({h=h_len, r=h_dia/2, fn=p.fn_low})
    cut = cad.modify.rotate(cut, {90, 0, 0})
    -- Position locally (hull is built at Z=0? No, stern is at lower_height/2)
    -- Wait, make_hull builds shapes. 
    -- stern was translated {0,0, h/2}.
    -- The hull's "Origin" is roughly the Step X=0, Z=0 (bottom).
    -- So p.hawse_x, p.hawse_z are global coords?
    -- Yes, separation of concerns.
    -- BUT hawsepipe is a hole in the hull. So we need to subtract it IN coords or map Global->Local.
    -- If Hull origin is (0,0,0) [Step, CenterY, Bottom], then == global.
    -- Let's check make_hull positioning in assembly. 
    -- It is NOT translated! `make_hull(p), -- Hull built around X=0`.
    -- So Global = for the Hull. Perfect.
    
    cut = cad.modify.translate(cut, {p.hawse_x, 0, p.hawse_z})
    
    hull = cad.combine.difference({hull, cut})
    
    return hull
end

function make_deck(p)
    -- deck = shapes.rounded_cube(...)
    return cad.create.cube({size={0,0,0}, center=true}) -- Placeholder
end

function make_cabin(p)
    -- Helper to generate a hull shape
    function get_shape(len, w_front, w_back, height_add, z_shift)
        h_add = height_add or 0
        z_off = z_shift or 0
        
        -- Calculate Sloped Heights based on current length
        half_len = len / 2
        rise = half_len * math.tan(math.rad(math.abs(p.roof_slope_angle)))
        
        h_base = p.cabin_height + h_add
        h_front = h_base + rise
        h_back = h_base - rise
        
        -- Z Centers for slices (base at Z=0 + z_off)
        -- Center = (Height / 2) + Offset
        z_front = (h_front / 2) + z_off
        z_back = (h_back / 2) + z_off
        
        -- Front slice
        s_front = cad.create.cube({size={0.1, w_front, h_front}, center=true})
        s_front = cad.modify.rotate(s_front, {0, p.cabin_front_slope, 0})
        s_front = cad.modify.translate(s_front, {len/2, 0, z_front})
        
        -- Back slice
        s_back = cad.create.cube({size={0.1, w_back, h_back}, center=true})
        s_back = cad.modify.translate(s_back, {-len/2, 0, z_back})
        
        return cad.combine.hull({s_front, s_back})
    end

    -- 1. Outer Shape
    outer = get_shape(p.cabin_length, p.cabin_front_width, p.cabin_back_width, 0, 0)
    
    -- 2. Inner Shape (Cavity)
    t = p.cabin_wall_thickness
    -- Ensure we don't go negative
    in_len = math.max(1, p.cabin_length - 2*t)
    in_w_front = math.max(1, p.cabin_front_width - 2*t)
    in_w_back = math.max(1, p.cabin_back_width - 2*t)
    
    -- Make inner taller (+2) and shift down (-1) to cut through top and bottom
    inner = get_shape(in_len, in_w_front, in_w_back, 2, -1)
    
    -- 3. Door Cutter (Arch)
    -- User: Hull of cube (bottom) and sphere (top) extruded over Y.
    -- Interpret as: Y-aligned Cylinder (top) + Y-aligned Cube (bottom) -> Hulled.
    
    d_w = p.door_width
    d_h = p.door_height
    d_d = p.door_depth
    radius = d_w / 2
    box_h = d_h - radius
    
    -- Top Cylinder (rotated to Y axis)
    -- Cylinder standard is Z. Rotate 90 deg X.
    top = cad.create.cylinder({h=d_d, r=radius, fn=p.fn_low})
    top = cad.modify.rotate(top, {90, 0, 0})
    -- Position: Z = box_h.
    top = cad.modify.translate(top, {0, 0, box_h})
    
    -- Bottom Box
    bot = cad.create.cube({size={d_w, d_d, box_h}, center=true})
    -- Center of box (height box_h) is at box_h/2
    bot = cad.modify.translate(bot, {0, 0, box_h/2})
    
    door_cut = cad.combine.hull({top, bot})
    
    -- Position Door locally
    -- p.door_z is global (9). p.deck_z is global (8).
    -- Cabin base is at global 8.
    -- So relative Z = p.door_z - p.deck_z?
    -- User said "base_z = 9". Deck is 8. So starts 1mm up.
    -- Our Z=0 corresponds to global p.deck_z.
    local_z = p.door_z - p.deck_z
    door_cut = cad.modify.translate(door_cut, {p.door_x, 0, local_z})
    
    -- 4. Front Window (Cube)
    fw_w = p.front_window_width
    fw_h = p.front_window_height
    fw_d = p.front_window_depth
    
    front_win = cad.create.cube({size={fw_d, fw_w, fw_h}, center=true})
    -- Rotate to match front wall slope
    front_win = cad.modify.rotate(front_win, {0, p.cabin_front_slope, 0})
    -- Position
    -- Global X, Z to Local
    fw_loc_x = p.front_window_x - p.cabin_x
    fw_loc_z = p.front_window_z - p.deck_z
    front_win = cad.modify.translate(front_win, {fw_loc_x, 0, fw_loc_z})
    
    -- 5. Back Window (Cylinder)
    rw_dia = p.rear_window_inner_diameter
    -- Depth needs to cut through back wall. Let's use front_window_depth or arbitrary.
    rw_depth = 20 
    
    rear_win = base_cylinder({h=rw_depth, r=rw_dia/2, fn=p.fn_low})
    -- Rotate to point along X (Front/Back)
    -- Cylinder is Z. Rotate 90 deg Y.
    rear_win = cad.modify.rotate(rear_win, {0, 90, 0})
    
    -- Position
    rw_loc_x = p.rear_window_x - p.cabin_x
    rw_loc_z = p.rear_window_z - p.deck_z
    rear_win = cad.modify.translate(rear_win, {rw_loc_x, 0, rw_loc_z})

    -- 6. Subtract All
    cabin = cad.combine.difference({outer, inner, door_cut, front_win, rear_win})
    
    -- No global positioning here
    
    return cabin
end

function make_roof(p)
    -- Front slice
    roof_front = cad.create.cube({size={0.1, p.roof_front_width, p.roof_height}, center=true})
    roof_front = cad.modify.translate(roof_front, {p.roof_length/2, 0, 0})
    
    -- Back slice
    roof_back = cad.create.cube({size={0.1, p.roof_back_width, p.roof_height}, center=true})
    roof_back = cad.modify.translate(roof_back, {-p.roof_length/2, 0, 0})
    
    -- Hull them together
    roof = cad.combine.hull({roof_front, roof_back})
    
    -- Apply rotation
    roof = cad.modify.rotate(roof, {0, p.roof_slope_angle, 0})
    
    -- No global positioning here
    
    return roof
end

function make_chimney(p)
    if p.chimney_inner_diameter >= p.chimney_outer_diameter then
        error("Chimney inner diameter (" .. p.chimney_inner_diameter .. ") must be smaller than outer diameter (" .. p.chimney_outer_diameter .. ")")
    end
    
    -- Shaft (Base Aligned)
    -- Cylinder takes radius, so divide diameter by 2
    chimney_shaft = base_cylinder({h=p.chimney_height, r=p.chimney_outer_diameter/2, fn=p.fn_low})
    
    -- Head (Base Aligned)
    chimney_head = base_cylinder({h=p.chimney_head_height, r=p.chimney_head_diameter/2, fn=p.fn_low})
    
    -- Stack head on top of shaft
    shaft_top_z = p.chimney_height
    chimney_head = cad.modify.translate(chimney_head, {0, 0, shaft_top_z})
    
    -- Combine Shaft and Head
    chimney_body = cad.combine.union({chimney_shaft, chimney_head})
    
    -- Inner Hole (Base Aligned)
    -- Must be taller than total height (shaft + head) to cut through.
    -- Shaft=10, Head=2.5 -> Total=12.5. 
    -- Or generally: p.chimney_height + p.chimney_head_height.
    total_h = p.chimney_height + p.chimney_head_height
    chimney_inner = base_cylinder({h=total_h + 2, r=p.chimney_inner_diameter/2, fn=p.fn_low})
    -- Shift down by 1 to cut through bottom (Z=0) and top (Z=total_h)
    chimney_inner = cad.modify.translate(chimney_inner, {0, 0, -1})
    
    chimney = cad.combine.difference({chimney_body, chimney_inner})
    
    -- No global positioning here
    
    return chimney
end

function make_cargo_box(p)
    -- Outer Box (Rounded)
    -- We can use shapes.rounded_cube or just a simple cube/cylinder combo?
    -- shapes.rounded_cube isn't defined in this snippet, let's look at imports. 
    -- `const shapes = require("shapes")`. So it exists.
    -- Let's assume shapes.rounded_cube(size_vec, radius, fn) returning centered or base?
    -- Standard library usually center.
    -- Let's implement manually with Hull of 4 cylinders if needed, but simple cube is safer for now if we don't know shapes API.
    -- User requested "cutting out cube shape" earlier, so simple is fine.
    
    c_h = p.cargo_height
    
    outer = cad.create.cube({size={p.cargo_outer_length, p.cargo_outer_width, c_h}, center=true})
    
    inner = cad.create.cube({size={p.cargo_inner_length, p.cargo_inner_width, c_h + 2}, center=true})
    inner = cad.modify.translate(inner, {0, 0, 2}) -- Shift up to NOT cut bottom?
    -- If we shift up 2, center goes up 2.
    -- Base of inner was at -h/2. New base at -h/2 + 2.
    -- We want to leave some floor thickness.
    
    box = cad.combine.difference({outer, inner})
    
    -- Align to Base Z=0
    box = cad.modify.translate(box, {0, 0, c_h/2})
    
    return box
end

-- ============================================================================
-- 5. ASSEMBLY
-- ============================================================================

calculate_derived(p)

-- NOTE: Original file had hull, deck, cargo box, etc commmented out. 
-- I will only include what was active in the last working version (Chimney, Roof, Cabin).

benchy = cad.combine.union({
    make_hull(p), -- Hull built around X=0 (Step)
    cad.modify.translate(make_chimney(p), {p.chimney_x, 0, p.chimney_z}),
    cad.modify.translate(make_roof(p), {p.roof_x, 0, p.roof_z}),
    cad.modify.translate(make_cabin(p), {p.cabin_x, 0, p.deck_z}),
    cad.modify.translate(make_cargo_box(p), {p.cargo_x, 0, p.deck_z})
})

-- Rounding the entire model (Minkowski sum with sphere)
-- benchy = cad.modify.round(benchy, 0.2, 32)

return benchy