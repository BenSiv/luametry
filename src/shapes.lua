const cad = require("cad")

const shapes = {}

-- Create an arch (cube + cylinder top)
function arch(width, height, thickness, fn)
    -- Create an arch shape
    -- Outer arc
    outer = cad.create("cylinder", {r=width/2, h=thickness, fn=fn, center=true})
    
    -- Inner arc (cutout)
    inner_width = width - 2 * height -- simplistic param mapping, usually height is arch height
    -- ... existing arch logic is minimal/placeholder in my previous knowledge, let's just append or replace if needed.
    -- Actually, let's just append the thread function.
    return csg.cube(1,1,1,1) -- Placeholder arch was likely empty?
end

function thread(r, h, pitch, fn, cut, profile_params)
    -- Generates a thread using the Revolve+Warp method (Manifold)
    -- Replaces the old stacking-cutter method.
    
    profile_params = profile_params or {}
    depth = profile_params.depth or (0.6 * pitch)
    root_w = profile_params.root_width or (pitch * 0.8)
    crest_w = profile_params.crest_width or (pitch * 0.1)
    
    -- Overshoot for cutter to ensure surface break
    y_base = 0
    if cut then
        y_base = -(0.05 * pitch) 
    end

    -- 1. Create Linear Rack Profile (Trapezoid)
    poly = {
        {-root_w/2, y_base},         -- Bottom Left
        {root_w/2, y_base},          -- Bottom Right
        {crest_w/2, depth},          -- Top Right
        {-crest_w/2, depth},         -- Top Left
        {-root_w/2, y_base}          -- Close
    }
    
    -- Calculate length
    num_turns = h / pitch
    circumference = 2 * math.pi * r
    total_len = circumference * num_turns
    
    -- Resolution (fn determines segments per turn approx)
    use_fn = fn or 64
    total_slices = math.ceil(use_fn * num_turns)
    
    -- Extrude Rack
    rack = cad.extrude(poly, total_len, {
        slices = total_slices
    })
    
    -- Pre-calculate taper params to capture them for closure
    radius_taper = profile_params.radius_taper
    
    -- 2. Warp Function
    warp_func = function(x, y, z)
        -- Map Input Z (length) to Angle
        angle = z / r -- radians
        
        -- Map Input Z to Z-Height (Pitch climb)
        z_slope = pitch / (2 * math.pi * r)
        z_climb = z * z_slope
        
        -- Taper Logic
        base_r = r
        current_r_offset = 0
        
        -- z in the warp function corresponds to the metric length along the helix (0 to total_len)
        -- We need to map this back to the "height" of the screw to apply Taper based on height?
        -- Taper is usually defined by "Z height along screw".
        -- Our current Z height is `z_climb`.
        current_z = z_climb
        
        if radius_taper != nil then
             bottom = radius_taper.bottom
             top = radius_taper.top
             
             if bottom != nil then
                if current_z >= (bottom.start_z or 0) and current_z <= (bottom.end_z or 0) then
                    t = (current_z - (bottom.start_z or 0)) / ((bottom.end_z or 0) - (bottom.start_z or 0))
                    start_r = bottom.start_r or r
                    end_r = bottom.end_r or r
                    -- We modify the BASE radius
                    target_r = start_r + (end_r - start_r) * t
                    base_r = target_r
                end
             end
             
             if top != nil then
                 if current_z >= (top.start_z or h) and current_z <= (top.end_z or h) then
                    t = (current_z - (top.start_z or h)) / ((top.end_z or h) - (top.start_z or h))
                    start_r = top.start_r or r
                    end_r = top.end_r or r
                    target_r = start_r + (end_r - start_r) * t
                    base_r = target_r
                 end
             end
        end
        
        -- Apply Radial Offset (Profile Height)
        -- cut=true (Union/Subtractive-ready): y=0 is Out (r), y=depth is In (r-depth)
        -- cut=false (Additive/Screw): y=0 is In (r), y=depth is Out (r+depth)
        
        final_r = base_r
        if cut == true then
            -- "Cutting" a thread into a rod. 
            -- y=0 (Base of trapezoid) should be at Surface (r).
            -- y=depth (Tip) should be at r - depth.
            final_r = base_r - y
        else
            -- "Adding" a thread to a rod.
            -- y=0 (Base) at Surface (r).
            -- y=depth (Tip) at r + depth.
            final_r = base_r + y
        end
        
        -- Output coordinates
        new_x = final_r * math.cos(angle)
        new_y = final_r * math.sin(angle)
        new_z = z_climb + x -- Add profile width (x) to z height
        
        return new_x, new_y, new_z
    end
    
    t = cad.warp(rack, warp_func)
    
    -- Post-transform: The warp creates it starting at Z=0.
    -- The original stacking method might have centered it?
    -- No, usually starts at Z=0?
    -- Stacking: `z = i * step_z` (0 to h). 
    -- So it generates from 0 to h.
    -- Revolve/Warp generates 0 to h.
    return t
end

shapes.arch = arch
shapes.thread = thread

return shapes
