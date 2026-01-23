# Luametry

Luametry is a Lua-based parametric CAD tool that generates STL files. It provides a clean, programmatic API for creating 3D geometry using Constructive Solid Geometry (CSG), powered by the [Manifold](https://github.com/elalish/manifold) geometry library.

## Directory Structure

- **`src/`**: Lua source code (`cad.lua`, `shapes.lua`, `stl.lua`) and C++ bindings (`csg_manifold.cpp`).
- **`tst/`**: Test scripts (e.g., `benchy.lua` for the 3DBenchy model).
- **`tls/`**: Tools, such as the `watch.lua` script for live preview.
- **`bld/`**: Build scripts (`build.sh`).
- **`out/`**: Output directory for generated STL files.
- **`doc/`**: Documentation and diagrams.
- **`obj/`**: Intermediate build objects.

## Usage

### 1. Build Luametry
Compile the project into a standalone static executable (`luametry`):
```bash
./bld/build.sh
```
This requires `g++`, `luam`, and `manifold` libraries installed.

### 2. Run a Script
Execute a Lua CAD script to generate a model:
```bash
./luametry tst/benchy.lua
```
The output will be saved to `out/benchy.stl` (as defined in the script).

### 3. Live Preview
Watch for file changes and automatically rebuild and view the model:
```bash
./live_edit.sh
```
- Requires `f3d` for visualization.
- Press **Up Arrow** in the viewer to reload the model after a rebuild.

## API Overview

```lua
const cad = require("cad")
const shapes = require("shapes")

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
