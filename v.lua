cad = require("cad"); man = cad.from_stl("out/nut.stl"); print("STL Volume:", cad.query.volume(man))
