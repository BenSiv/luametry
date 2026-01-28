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
    hull_sphere_radius = 30,
    hull_scale_x = 1.0,
    hull_scale_y = 0.52,
    hull_scale_z = 0.42,
    hull_inner_scale = 0.95,
    hull_inner_scale = 0.95,
    hull_inner_x = -3,
    hull_inner_z = 6,
    bow_cutter_radius = 45,
    bow_cutter_x = 60,
    bow_cutter_y = 32,
    bow_overhang_angle = 40,  -- degrees
    
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
    front_window_x = 4,
    front_window_z = 20,
    
    -- Rear window (circular)
    rear_window_inner_diameter = 9,
    rear_window_outer_diameter = 12,
    rear_window_x = -20,
    rear_window_z = 20,
    
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
    -- 1. HULL BASE
    -- hull_base = cad.create.sphere({r=p.hull_sphere_radius, fn=p.fn_high})
    -- (Commented out in original, keeping strict structure but empty implementation as it was commented out)
    return cad.create.cube({size={0,0,0}, center=true}) -- Placeholder for now as original code was commented out
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
    
    -- 4. Subtract Inner and Door from Outer
    cabin = cad.combine.difference({outer, inner, door_cut})
    
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

-- ============================================================================
-- 5. ASSEMBLY
-- ============================================================================

calculate_derived(p)

-- NOTE: Original file had hull, deck, cargo box, etc commmented out. 
-- I will only include what was active in the last working version (Chimney, Roof, Cabin).

benchy = cad.combine.union({
    cad.modify.translate(make_chimney(p), {p.chimney_x, 0, p.chimney_z}),
    cad.modify.translate(make_roof(p), {p.roof_x, 0, p.roof_z}),
    cad.modify.translate(make_cabin(p), {p.cabin_x, 0, p.deck_z})
})

print("Exporting 3DBenchy...")
if cad.export(benchy, "out/benchy.stl") then
    print("Success: out/benchy.stl")
else
    print("Failure")
end
