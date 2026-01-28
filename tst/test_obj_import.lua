cad = require("cad"); nut = cad.from_obj("out/nut.obj"); print("Nut Volume:", cad.query.volume(nut))
