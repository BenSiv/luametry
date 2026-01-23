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

test_basic_solid()