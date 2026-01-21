package.path = "src/?.lua;" .. package.path

const stl = require("stl")

function test_basic_solid()

    solid = stl.create_solid("trig")

    solid = stl.add_facet(
        solid,
        {0,0,1},
        {0,0,0},
        {1,0,0},
        {1,1,0}
    )
    
    solid = stl.add_facet(
        solid,
        {0,0,1},
        {0,0,0},
        {0,1,0},
        {1,1,0}
    )
    
    stl_results = stl.encode_solid(solid)
    print(stl_results)
end

-- test_basic_solid()

function test_polygon()

    -- solid = stl.polygon({{0,0,0},{0,0,1}}) -- only 2 points
    -- solid = stl.polygon({{0,0,0},{0,0,"1"},{0,1,1}}) -- incorrect type
    -- solid = stl.polygon({{0,0,0},{0,0,1},{0,0,1}}) -- duplicate points
    solid = stl.polygon({{0,0,0},{0,0,1},{0,1,1},{1,1,1}})
    
    stl_results = stl.encode_solid(solid)
    print(stl_results)
end

-- test_polygon()

function test_square()

    -- solid = stl.square(5)
    solid = stl.square(5, true)
    
    stl_results = stl.encode_solid(solid)
    print(stl_results)
end

-- test_square()

function test_rectangle()

    -- solid = stl.rectangle(5, 7)
    solid = stl.rectangle(5, 7, true)
    
    stl_results = stl.encode_solid(solid)
    print(stl_results)
end

-- test_rectangle()

function test_triangle()

    solid = stl.triangle(5, 7)
    
    stl_results = stl.encode_solid(solid)
    print(stl_results)
end

test_triangle()

function test_circle()

    solid = stl.circle(5, 20)
    
    stl_results = stl.encode_solid(solid)
    print(stl_results)
end

-- test_circle()