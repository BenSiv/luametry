-- slicer.lua
-- Utilities for slicing meshes and analyzing 2D cross-sections

const cad = require("cad")
const slicer = {}

-- Slice a triangle with a Z plane
function slice_triangle(v1, v2, v3, z)
    verts = {v1, v2, v3}
    above = {}
    below = {}
    
    for i, v in ipairs(verts) do
        if v.z >= z then
            table.insert(above, v)
        else
            table.insert(below, v)
        end
    end
    
    -- No intersection
    if #above == 0 or #below == 0 then
        return nil
    end
    
    -- Helper to interpolate Z
    function intersect(p1, p2, z_plane)
        t = (z_plane - p1.z) / (p2.z - p1.z)
        return {
            x = p1.x + t * (p2.x - p1.x),
            y = p1.y + t * (p2.y - p1.y),
            z = z_plane
        }
    end
    
    points = {}
    
    if #above == 1 then
        -- 1 point above, 2 below -> triangle is cut near the top vertex
        -- Intersect (above[1] -> below[1]) and (above[1] -> below[2])
        p1 = intersect(above[1], below[1], z)
        p2 = intersect(above[1], below[2], z)
        return {p1, p2}
    else
        -- 2 points above, 1 below -> triangle is cut near the bottom vertex
        -- Intersect (below[1] -> above[1]) and (below[1] -> above[2])
        p1 = intersect(below[1], above[1], z)
        p2 = intersect(below[1], above[2], z)
        return {p1, p2}
    end
end

-- Slice mesh at a given position along an axis ("x", "y", "z")
function slicer.slice_mesh(mesh, pos, axis)
    axis = axis or "z"
    segments = {}
    
    -- Helper to swap coordinates for slicing logic (which assumes Z slice)
    function to_slice_space(v)
        if axis == "z" then return v end
        if axis == "y" then return {x=v.x, y=v.z, z=v.y} end
        if axis == "x" then return {x=v.y, y=v.z, z=v.x} end -- Z becomes X
    end
    
    function from_slice_space(v)
        if axis == "z" then return v end
        if axis == "y" then return {x=v.x, y=v.z, z=v.y} end -- Swap back
        if axis == "x" then return {x=v.z, y=v.x, z=v.y} end
    end
    
    for _, facet in ipairs(mesh.facets) do
        v1 = to_slice_space(facet.vertices[1])
        v2 = to_slice_space(facet.vertices[2])
        v3 = to_slice_space(facet.vertices[3])
        
        -- Use existing Z-slice logic
        seg = slice_triangle(v1, v2, v3, pos)
        
        if seg != nil then
            -- Transform back
            p1 = from_slice_space(seg[1])
            p2 = from_slice_space(seg[2])
            table.insert(segments, {p1, p2})
        end
    end
    
    return segments
end

-- Convert 2D segments to 3D shape for visualization
function slicer.segments_to_shape(segments, thickness)
    thickness = thickness or 0.2
    shapes = {}
    
    for _, seg in ipairs(segments) do
        p1 = seg[1]
        p2 = seg[2]
        
        dx = p2.x - p1.x
        dy = p2.y - p1.y
        len = math.sqrt(dx*dx + dy*dy)
        
        if len > 0.001 then
            angle = math.deg(math.atan2(dy, dx))
            x_mid = (p1.x + p2.x) / 2
            y_mid = (p1.y + p2.y) / 2
            
            c = cad.create("cube", {len, thickness, thickness, center=true})
            c = cad.transform("rotate", c, {0, 0, angle})
            c = cad.transform("translate", c, {x_mid, y_mid, p1.z})
            table.insert(shapes, c)
        end
    end
    
    if #shapes == 0 then
        return cad.create("cube", {0,0,0})
    end
    
    -- Union all small segments
    -- Optimization: Union in chunks to avoid stack overflow or O(N^2) issues in Manifold
    function union_chunk(list)
        if #list == 0 then return cad.create("cube", {0,0,0}) end
        if #list == 1 then return list[1] end
        return cad.boolean("union", list)
    end
    
    chunk_size = 50
    chunks = {}
    current_chunk = {}
    
    for _, s in ipairs(shapes) do
        table.insert(current_chunk, s)
        if #current_chunk >= chunk_size then
            table.insert(chunks, union_chunk(current_chunk))
            current_chunk = {}
        end
    end
    if #current_chunk > 0 then
        table.insert(chunks, union_chunk(current_chunk))
    end
    
    return union_chunk(chunks)
end

-- Generate a "projection" by slicing densely along an axis
function slicer.project_mesh(mesh, axis, step)
    step = step or 1.0
    
    -- Determine range
    min_val = 999999
    max_val = -999999
    
    for _, f in ipairs(mesh.facets) do
        for _, v in ipairs(f.vertices) do
            val = v[axis]
            if val < min_val then min_val = val end
            if val > max_val then max_val = val end
        end
    end
    
    projections = {}
    current_pos = min_val + step
    
    while current_pos < max_val do
        segs = slicer.slice_mesh(mesh, current_pos, axis)
        if #segs > 0 then
            -- Convert to thin shape
            shape = slicer.segments_to_shape(segs, 0.2)
            table.insert(projections, shape)
        end
        current_pos = current_pos + step
    end
    
    if #projections == 0 then return cad.create("cube", {0,0,0}) end
    
    -- Union all slices (flattened visually)
    final_shape = projections[1]
    if #projections > 1 then
        final_shape = cad.boolean("union", projections)
    end
    
    return final_shape
end

-- Calculate bounding box of segments
function slicer.measure_bounds(segments)
    if #segments == 0 then return {0,0,0,0} end
    
    min_x = 999999
    max_x = -999999
    min_y = 999999
    max_y = -999999
    
    for _, seg in ipairs(segments) do
        for _, p in ipairs(seg) do
            if p.x < min_x then min_x = p.x end
            if p.x > max_x then max_x = p.x end
            if p.y < min_y then min_y = p.y end
            if p.y > max_y then max_y = p.y end
        end
    end
    
    width = max_x - min_x
    length = max_y - min_y
    center_x = (min_x + max_x) / 2
    center_y = (min_y + max_y) / 2
    
    return {width, length, center_x, center_y, min_x, max_x, min_y, max_y}
end

return slicer
