package.path = package.path .. ";./src/?.lua"
cad = require("cad")

print("Modeling Parametric Golf Ball")

const ball_radius = 10
golf_ball = cad.create("sphere", {r=ball_radius})
const num_dimples = 100
const phi = (math.sqrt(5) - 1) / 2  -- golden ratio conjugate

-- Calculate dimple radius to cover surface (heuristic based on N=300, r=0.6)
-- coverage proportional to N * r^2 = constant
-- r = k / sqrt(N)
-- k = 0.6 * sqrt(300) = 10.4
dimple_radius = 10.4 / math.sqrt(num_dimples)

dimples = {}

-- Generate initial points using Fibonacci Lattice
points = {}
for i = 1, num_dimples do
    z = (2 * i - 1) / num_dimples - 1
    radius_at_z = math.sqrt(1 - z*z)
    theta = 2 * math.pi * i * phi
    
    x = radius_at_z * math.cos(theta) * ball_radius
    y = radius_at_z * math.sin(theta) * ball_radius
    z = z * ball_radius
    
    table.insert(points, {x=x, y=y, z=z})
end

-- Relax points (simple repulsion)
iterations = 20
repulsion_force = 0.5
limit_dist_sq = (ball_radius * 4)^2 -- Check neighbors within reasonable distance

print("Relaxing points (" .. iterations .. " iterations)...")

for iter = 1, iterations do
    forces = {}
    for i = 1, num_dimples do forces[i] = {x=0, y=0, z=0} end
    
    for i = 1, num_dimples do
        p1 = points[i]
        for j = i + 1, num_dimples do
            p2 = points[j]
            dx = p1.x - p2.x
            dy = p1.y - p2.y
            dz = p1.z - p2.z
            d2 = dx*dx + dy*dy + dz*dz
            
            if d2 < limit_dist_sq and d2 > 0.001 then
                -- Force inverse to distance squared
                f = repulsion_force / d2
                fx = dx * f
                fy = dy * f
                fz = dz * f
                
                forces[i].x = forces[i].x + fx
                forces[i].y = forces[i].y + fy
                forces[i].z = forces[i].z + fz
                
                forces[j].x = forces[j].x - fx
                forces[j].y = forces[j].y - fy
                forces[j].z = forces[j].z - fz
            end
        end
    end
    
    -- Apply forces and project back to sphere
    for i = 1, num_dimples do
        p = points[i]
        f = forces[i]
        
        p.x = p.x + f.x
        p.y = p.y + f.y
        p.z = p.z + f.z
        
        -- Normalize
        d = math.sqrt(p.x*p.x + p.y*p.y + p.z*p.z)
        p.x = (p.x / d) * ball_radius
        p.y = (p.y / d) * ball_radius
        p.z = (p.z / d) * ball_radius
    end
end

-- Create dimples at relaxed positions
for _, p in ipairs(points) do
    dimple = cad.create("sphere", {r=dimple_radius, fn=16})
    dimple = cad.transform("translate", dimple, {p.x, p.y, p.z})
    table.insert(dimples, dimple)
end

-- Subtract all dimples
table.insert(dimples, 1, golf_ball) -- Prepend the main ball
golf_ball = cad.boolean("difference", dimples)

output_file = "out/golf_ball.stl"
print("Exporting Golf Ball")
if cad.export(golf_ball, output_file) then
    print("Success: " .. output_file)
else
    print("Failure")
end