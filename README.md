# Luametry

Luametry is a Lua-based parametric CAD tool that generates STL files. It provides a clean, programmatic API for creating 3D geometry using Constructive Solid Geometry (CSG), powered by the [Manifold](https://github.com/elalish/manifold) geometry library.

## Directory Structure

- **`src/`**: Lua source code (`cad.lua`, `shapes.lua`, `stl.lua`, `cli.lua`) and C++ bindings.
- **`tst/`**: Test scripts (e.g., `benchy.lua` for the 3DBenchy model).
- **`bld/`**: Build scripts (`build.sh`).
- **`bin/`**: Output directory for the compiled binary (gitignored).
- **`out/`**: Output directory for generated STL files.
- **`doc/`**: Documentation and diagrams.

## Build

Compile the project into a standalone static executable:
```bash
./bld/build.sh
```
This requires `g++`, `luam`, and `manifold` libraries installed.

## Usage

```bash
# Run a CAD script
./bin/luametry -c run -s tst/benchy.lua

# Watch files and rebuild on change
./bin/luametry -c watch -s tst/benchy.lua

# Live preview with 3D viewer (default: f3d)
./bin/luametry -c live -s tst/benchy.lua

# Use a different viewer
./bin/luametry -c live -s tst/benchy.lua -v meshlab

# Or set via environment variable
export LUAMETRY_VIEWER=meshlab
./bin/luametry -c live -s tst/benchy.lua
```

## API Overview

```lua
cad = require("cad")
shapes = require("shapes")

-- Create shapes
cube = cad.create("cube", {size={10, 10, 10}, center=true})
sphere = cad.create("sphere", {r=5, fn=32})

-- CSG Operations
part = cad.boolean("difference", {cube, sphere})

-- High-level Helpers
box = shapes.rounded_cube(10, 1, 32)
arch = shapes.arch(10, 5, 10, 32)

-- Export
cad.export(part, "out/model.stl")
```

## License

MIT License. See [LICENSE](LICENSE).

**Dependencies:**
- [Manifold](https://github.com/elalish/manifold): Apache 2.0
- [Lua](https://www.lua.org/): MIT
- [LuaFileSystem (lfs)](https://github.com/lunarmodules/luafilesystem): MIT
