-- Declarative static build manifest for Luametry (C++ Manifold CSG engine).
return {
    bin = "luametry",
    entry = "entry.lua",
    luam = "bc0140e9c7144164808b3f7d6085fe3dd2a18e8a",
    with = {"lfs", "yaml"},
    always_include = {"shapes", "slicer", "paths", "dkjson"},
    native = {
        {
            name = "csg.manifold",
            luaopen = "luaopen_csg_manifold",
            sources = {"src/csg_manifold.cpp"},
            cxx = true,
            cflags_env = "MANIFOLD_CFLAGS",
            ldflags_env = "MANIFOLD_LDFLAGS",
        },
    },
}
