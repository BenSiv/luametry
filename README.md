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
# Run a CAD script (generates STL)
./bin/luametry run tst/benchy.lua

# Live preview with 3D viewer (default: f3d)
./bin/luametry live tst/benchy.lua

# Use a different viewer
./bin/luametry live tst/benchy.lua -v meshlab
```

## The Luam Dialect

Luametry uses **Luam**, a modernized Lua dialect:
*   **Local by Default**: Variables are local to scope (no `local` keyword needed).
*   **Modern Syntax**: `!=` for inequality, `const` for constants, `"""multiline strings"""`.
*   **Procedural**: Simplified API designed for geometry pipelines.

## API Overview

```lua
-- Cad & Shapes are global or required modules
const cad = require("cad")
const shapes = require("shapes")

-- Create shapes (long-form aliases supported)
cube = cad.create.cube({size=10, center=true})
sphere = cad.create.sphere({radius=5, segments=32})

-- CSG Operations
part = cad.combine.difference({cube, sphere})

-- High-level Shapes
-- Thread with subtractive option (cut=true)
bolt_thread = shapes.thread({
    radius=5, 
    height=20, 
    pitch=1.0, 
    cut=true
})

-- Arch
arch = shapes.arch({width=10, height=5, thickness=10, segments=32})

-- Export
cad.export(part, "out/model.stl")
```

```lua
-- Extrude
poly = {{0,0}, {10,0}, {5,8}}
prism = cad.extrude(poly, 10, {twist=90, scale_x=0.5})

-- Export
cad.export(part, "out/model.stl")
```

## License

MIT License. See [LICENSE](LICENSE).

**Dependencies:**
- [Manifold](https://github.com/elalish/manifold): Apache 2.0
- [Lua](https://www.lua.org/): MIT
- [LuaFileSystem (lfs)](https://github.com/lunarmodules/luafilesystem): MIT
