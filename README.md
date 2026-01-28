# Luametry

Luametry is a professional, Lua-based parametric CAD tool designed for engineers and makers. It provides a clean, programmatic API for creating complex 3D geometry using Constructive Solid Geometry (CSG), powered by the lightning-fast [Manifold](https://github.com/elalish/manifold) geometry library.

## Key Features

- **Professional Export Suite**: Support for **STL**, **STEP** (industrial CAD), **OBJ**, and **3MF** (additive manufacturing).
- **Text Extrusion**: Generate 3D text with configurable fonts, weight, and rounding.
- **Parametric Operations**: Native support for **Fillets** (rounding) and **Chamfers** (beveling).
- **Modern CLI**: Live preview mode, high-quality PNG screenshots, and easy system installation.
- **Luam Dialect**: Uses a modernized Lua with `!=` support, multi-line strings, and local-by-default scoping.
- **100% Verified**: Every feature is rigorously tested with an automated test suite.

---

## Installation

### Prerequisites
Requires `g++`, `luam` (static lua builder), and the `manifold` C++ library.

### Build & Install
```bash
# Build the binary
./bld/build.sh

# Install globally to /usr/local/bin
sudo luametry install
```

---

## CLI Guide

Luametry comes with a powerful command-line interface:

- **`luametry run <script>`**: Executes a script and generates an STL.
- **`luametry live <script>`**: Starts live preview mode. Watches for file changes and reloads the 3D viewer (default: `f3d`) instantly.
- **`luametry screenshot <script>`**: Generates a high-quality shaded PNG of your model.
- **`luametry export <script> -o <file>`**: Exports to a specific format (detects `.step`, `.obj`, `.3mf`, `.stl`).
- **`luametry update`**: Pulls the latest project updates and rebuilds.

---

## API Overview

### 1. Primitive Shapes
- `cad.cube({size, center})`
- `cad.sphere({r, fn})`
- `cad.cylinder({h, r1, r2, fn, center})`
- `cad.torus(major_r, minor_r, major_fn, minor_fn)`

### 2. Professional Operations
- **Fillet**: `cad.fillet(shape, radius)` (alias: `cad.round`)
- **Chamfer**: `cad.chamfer(shape, size)` (alias: `cad.bevel`)
- **Extrude**: `cad.extrude(polygon, height, params)`
- **Revolve**: `cad.revolve(polygon, segments, degrees)`

### 3. Text Generation
```lua
-- Create 3D labels easily
label = cad.text("LUAMETRY", {
    h = 10,       -- Height
    t = 1.5,      -- Stroke thickness
    z = 2.0,      -- Extrusion depth
    rounded = true -- Smooth joints
})
```

### 4. Boolean Operations
- `cad.union({shapes})`
- `cad.difference(base, subtract)`
- `cad.intersection(a, b)`
- `cad.hull({shapes})`

---

## Configuration

You can customize Luametry via `~/.config/luametry/settings.lua`:
```lua
return {
    viewer = "f3d",                 -- Your preferred 3D viewer
    viewer_args = "--up +Z --shading-model pbr", 
    default_output = "out/result.stl"
}
```

---

## Development

Run the full test suite to ensure stability:
```bash
./bld/build.sh --test
```

## License

MIT License. See [LICENSE](LICENSE).

**Core Dependencies:**
- [Manifold](https://github.com/elalish/manifold) (Apache 2.0)
- [Lua](https://www.lua.org/) (MIT)
- [LuaFileSystem](https://github.com/lunarmodules/luafilesystem) (MIT)
