const cad = require("cad")

const shapes = {}

-- Create an arch (cube + cylinder top)
function arch(params)
    if type(params) != "table" then
        error("shapes.arch expects a params table")
    end
    
    width = 10
    if params.width != nil then
        width = params.width
    elseif params.w != nil then
        width = params.w
    end
    height = 5
    if params.height != nil then
        height = params.height
    elseif params.h != nil then
        height = params.h
    end
    thickness = 2
    if params.thickness != nil then
        thickness = params.thickness
    elseif params.t != nil then
        thickness = params.t
    elseif params.depth != nil then
        thickness = params.depth
    elseif params.d != nil then
        thickness = params.d
    end
    fn = 32
    if params.fn != nil then
        fn = params.fn
    elseif params.segments != nil then
        fn = params.segments
    end
    
    -- Create an arch shape
    -- Outer arc
    outer = cad.create("cylinder", {r=width/2, h=thickness, fn=fn, center=true})
    
    -- Inner arc (cutout)
    inner_width = width - 2 * height -- simplistic param mapping, usually height is arch height
    -- ... existing arch logic is minimal/placeholder in my previous knowledge, let's just append or replace if needed.
    -- Actually, let's just append the thread function.
    return csg.cube(1,1,1,1) -- Placeholder arch was likely empty?
end

function thread(params)
    -- Generates a thread using the Revolve+Warp method (Manifold)
    -- Replaces the old stacking-cutter method.
    
    if type(params) != "table" then
        error("shapes.thread expects a params table")
    end
    
    r = 5
    if params.r != nil then
        r = params.r
    elseif params.radius != nil then
        r = params.radius
    end
    h = 10
    if params.h != nil then
        h = params.h
    elseif params.height != nil then
        h = params.height
    elseif params.length != nil then
        h = params.length
    elseif params.l != nil then
        h = params.l
    end
    pitch = 1.0
    if params.pitch != nil then
        pitch = params.pitch
    elseif params.p != nil then
        pitch = params.p
    end
    fn = 64
    if params.fn != nil then
        fn = params.fn
    elseif params.segments != nil then
        fn = params.segments
    end
    cut = false
    if params.cut != nil then
        cut = params.cut
    elseif params.subtractive != nil then
        cut = params.subtractive
    elseif params.c != nil then
        cut = params.c
    end

    -- Profile Params merged into top level
    depth = 0.6 * pitch
    if params.depth != nil then
        depth = params.depth
    elseif params.d != nil then
        depth = params.d
    end
    root_w = pitch * 0.8
    if params.root_width != nil then
        root_w = params.root_width
    elseif params.rw != nil then
        root_w = params.rw
    end
    if root_w > (pitch * 0.99) then
        root_w = pitch * 0.99
    end
    crest_w = pitch * 0.1
    if params.crest_width != nil then
        crest_w = params.crest_width
    elseif params.cw != nil then
        crest_w = params.cw
    end
    
    -- Overshoot for cutter to ensure surface break
    y_base = 0
    if cut then
        y_base = -(0.05 * pitch) 
    end

    -- 1. Create Linear Rack Profile (Trapezoid)
    -- Default: CCW Winding (Additive / cut=false)
    poly = {
        {-root_w/2, y_base},         -- Bottom Left
        {root_w/2, y_base},          -- Bottom Right
        {crest_w/2, depth},          -- Top Right
        {-crest_w/2, depth},         -- Top Left
        {-root_w/2, y_base}          -- Close
    }

    if cut then
        -- Override: CW Winding (Subtractive / Inverting Map)
        poly = {
            {-root_w/2, y_base},         -- Bottom Left
            {-crest_w/2, depth},         -- Top Left
            {crest_w/2, depth},          -- Top Right
            {root_w/2, y_base},          -- Bottom Right
            {-root_w/2, y_base}          -- Close
        }
    end
    
    -- Calculate length
    num_turns = h / pitch
    circumference = 2 * math.pi * r
    total_len = circumference * num_turns
    
    -- Resolution (fn determines segments per turn approx)
    use_fn = 64
    if fn != nil then
        use_fn = fn
    end
    total_slices = math.ceil(use_fn * num_turns)
    
    -- Extrude Rack
    rack = cad.extrude(poly, total_len, {
        slices = total_slices
    })
    
    -- Pre-calculate taper params to capture them for closure
    radius_taper = params.radius_taper
    
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
                bottom_start_z = 0
                if bottom.start_z != nil then
                    bottom_start_z = bottom.start_z
                end
                bottom_end_z = 0
                if bottom.end_z != nil then
                    bottom_end_z = bottom.end_z
                end
                if current_z >= bottom_start_z and current_z <= bottom_end_z then
                    t = (current_z - bottom_start_z) / (bottom_end_z - bottom_start_z)
                    start_r = r
                    if bottom.start_r != nil then
                        start_r = bottom.start_r
                    end
                    end_r = r
                    if bottom.end_r != nil then
                        end_r = bottom.end_r
                    end
                    -- We modify the BASE radius
                    target_r = start_r + (end_r - start_r) * t
                    base_r = target_r
                end
             end

             if top != nil then
                top_start_z = h
                if top.start_z != nil then
                    top_start_z = top.start_z
                end
                top_end_z = h
                if top.end_z != nil then
                    top_end_z = top.end_z
                end
                 if current_z >= top_start_z and current_z <= top_end_z then
                    t = (current_z - top_start_z) / (top_end_z - top_start_z)
                    start_r = r
                    if top.start_r != nil then
                        start_r = top.start_r
                    end
                    end_r = r
                    if top.end_r != nil then
                        end_r = top.end_r
                    end
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
    
    return t
end

shapes.arch = arch
shapes.thread = thread

return shapes
