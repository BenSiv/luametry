
cad = require("cad")
shapes = require("shapes") -- Assuming standard shapes might be needed or loaded via cad?
-- cad.lua doesn't auto-load shapes.lua into global but `shapes` module exists.
-- Let's check hex_bolt.lua to see how it works.
package.loaded.import_mode = true
create_bolt = dofile("tst/examples/hex_bolt.lua")
package.loaded.import_mode = nil

bolt = create_bolt({
    fn = 16,
    tool_fn = 4,
    head_dia = 12,
    head_height = 5,
    shaft_dia = 6,
    length = 20,
    pitch = 1.5
})

-- cad.export(bolt, "out/hex_bolt.step")
return bolt
