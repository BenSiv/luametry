-- src/ascii.lua
-- ASCII Art Renderer for Luametry

ascii = {}

-- Shading ramp
ascii.ramp = "$@B%8&WM#*oahkbdpqwmZO0QLCJUYXzcvunxrjft/\\|()1{}[]?-_+~<>i!lI;:,\"^`'. "

function ascii.render_mesh(mesh, width, height)
    width = width or 80
    height = height or 40
    
    -- Aspect ratio correction (characters are taller than wide)
    char_aspect = 2.0
    
    -- Initialize buffers
    zbuffer = {}
    framebuffer = {}
    for i = 1, width * height do
        zbuffer[i] = -1e10
        framebuffer[i] = ' '
    end
    
    -- Calculate bounds and scale
    min_x, max_x = 1e10, -1e10
    min_y, max_y = 1e10, -1e10
    min_z, max_z = 1e10, -1e10
    
    for _, v in ipairs(mesh.verts) do
        if v[1] < min_x then min_x = v[1] end
        if v[1] > max_x then max_x = v[1] end
        if v[2] < min_y then min_y = v[2] end
        if v[2] > max_y then max_y = v[2] end
        if v[3] < min_z then min_z = v[3] end
        if v[3] > max_z then max_z = v[3] end
    end
    
    dx = max_x - min_x
    dy = max_y - min_y
    dz = max_z - min_z
    max_dim = dx
    if dy > max_dim then max_dim = dy end
    if dz > max_dim then max_dim = dz end
    
    if max_dim == 0 then max_dim = 1 end
    
    scale_x = (width - 2) / max_dim
    scale_y = (height - 2) / max_dim * char_aspect
    
    center_x = (min_x + max_x) / 2
    center_y = (min_y + max_y) / 2
    
    -- Standard view (isometric-ish)
    light = {0.577, 0.577, 0.577} -- 1/sqrt(3)
    
    for _, f in ipairs(mesh.faces) do
        v1 = mesh.verts[f[1]]
        v2 = mesh.verts[f[2]]
        v3 = mesh.verts[f[3]]
        
        -- Screen space coords
        x1 = (v1[1] - center_x) * scale_x + width / 2
        y1 = (v1[2] - center_y) * scale_y + height / 2
        z1 = v1[3]
        
        x2 = (v2[1] - center_x) * scale_x + width / 2
        y2 = (v2[2] - center_y) * scale_y + height / 2
        z2 = v2[3]
        
        x3 = (v3[1] - center_x) * scale_x + width / 2
        y3 = (v3[2] - center_y) * scale_y + height / 2
        z3 = v3[3]
        
        -- Normal for shading
        ux, uy, uz = v2[1]-v1[1], v2[2]-v1[2], v2[3]-v1[3]
        vx, vy, vz = v3[1]-v1[1], v3[2]-v1[2], v3[3]-v1[3]
        nx, ny, nz = uy*vz - uz*vy, uz*vx - ux*vz, ux*vy - uy*vx
        
        len = math.sqrt(nx*nx + ny*ny + nz*nz)
        if len > 0 then
            nx = nx/len; ny = ny/len; nz = nz/len
            
            -- Simple diffuse shading
            dot = nx * light[1] + ny * light[2] + nz * light[3]
            if dot < 0 then dot = 0 end
            
            char_idx = math.floor((1 - dot) * (#ascii.ramp - 1)) + 1
            char = string.sub(ascii.ramp, char_idx, char_idx)
            
            -- Rasterize Triangle (Simple bounding box)
            bx1 = math.floor(math.min(x1, x2, x3))
            bx2 = math.ceil(math.max(x1, x2, x3))
            by1 = math.floor(math.min(y1, y2, y3))
            by2 = math.ceil(math.max(y1, y2, y3))
            
            if bx1 < 1 then bx1 = 1 end
            if bx2 > width then bx2 = width end
            if by1 < 1 then by1 = 1 end
            if by2 > height then by2 = height end
            
            for py = by1, by2 do
                for px = bx1, bx2 do
                    -- Barycentric coordinates for inside test and Z
                    denom = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)
                    if math.abs(denom) > 1e-6 then
                        w1 = ((y2 - y3) * (px - x3) + (x3 - x2) * (py - y3)) / denom
                        w2 = ((y3 - y1) * (px - x3) + (x1 - x3) * (py - y3)) / denom
                        w3 = 1 - w1 - w2
                        
                        if w1 >= 0 and w2 >= 0 and w3 >= 0 then
                            pz = w1 * z1 + w2 * z2 + w3 * z3
                            idx = (py - 1) * width + px
                            if pz > zbuffer[idx] then
                                zbuffer[idx] = pz
                                framebuffer[idx] = char
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Print frame
    lines = {}
    for y = height, 1, -1 do
        row = ""
        for x = 1, width do
            row = row .. framebuffer[(y - 1) * width + x]
        end
        table.insert(lines, row)
    end
    return table.concat(lines, "\n")
end

return ascii
