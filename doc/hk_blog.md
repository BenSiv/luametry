# Show HN: Luametry - Parametric CAD for Lua Developers (built on Manifold)

I've been working on a new tool called **Luametry**, and I wanted to share it with the community. It's a high-performance programmatic CAD tool designed for developers who want the power of a real programming language for their 3D modeling.

## The Problem with OpenSCAD

If you've used OpenSCAD, you know the struggle. It's fantastic for getting started, but as your models grow in complexity, you hit a wall. You start missing the features of a modern programming language: proper modules, string manipulation, package management, and first-class functions. The custom syntax can feel limiting when you're trying to build complex, reusable libraries.

## The Luam Dialect

Luametry solves this by using **Luam**, a modernized dialect of Lua designed for clean, safe modeling code:

*   **Local by Default**: No more spamming `local`. Variables are local to their scope by default, preventing accidental global pollution.
*   **Procedural First**: We stripped away complex OOP features. Luam encourages simple, composable procedural code—perfect for geometry pipelines.
*   **Modern Syntax**: Enjoy modern conveniences like `!=` for inequality, `const` for immutability, and proper `"""multiline strings"""`.

## Powered by Manifold

Under the hood, Luametry uses the **Manifold** geometry kernel. Manifold is fast and robust, capable of handling complex CSG operations (Unions, Differences, Intersections) that can be challenging for other engines. It guarantees manifold (watertight) meshes, making models 3D-printing ready by default.

## What it Looks Like

Here is a complete example of creating a threaded hex bolt. This demonstrates the `shapes` library, the `cad` API, and the new explicit argument aliases for readability.

[Rendered Bolt](images/bolt_render.png)

```lua
-- Luam supports 'const' for immutable variables
const cad = require("cad")
const shapes = require("shapes")

-- 1. Create Head
head = cad.create.cylinder({
    radius=5, 
    height=3, 
    segments=6, -- Hexagon
    center=true
})
-- Align head (move UP)
head = cad.modify.translate(head, {0, 0, 1.5})

-- 2. Create Shaft
shaft = cad.create.cylinder({
    radius=2.5,  -- 5mm diameter
    height=20,   -- 20mm length
    segments=32,
    center=true
})
-- Align shaft (move DOWN)
shaft = cad.modify.translate(shaft, {0, 0, -10})

-- 3. Create Thread (Cutter)
-- We set cut=true to generate a "negative" thread shape
thread_cutter = shapes.thread({
    radius=2.5, 
    height=15, 
    pitch=1.0, 
    segments=32,
    cut=true -- Subtractive mode
})
-- Align thread (move to bottom of shaft)
thread_cutter = cad.modify.translate(thread_cutter, {0, 0, -20})

-- 4. Apply Theading
-- Subtract the thread cutter from the shaft
threaded_shaft = cad.combine.difference({shaft, thread_cutter})

-- 5. Final Assembly
bolt = cad.combine.union({head, threaded_shaft})

cad.export(bolt, "bolt.stl")
```

## Key Features

*   **Fast Geometry**: Powered by [Manifold](https://github.com/elalish/manifold) for CSG operations.
*   **Live Reloading**: Run `luametry live script.lua` to see changes instantly in your viewer.
*   **Standard Library**: Built-in `shapes` module for common parts like threads, gears, and arches.

## Try It Out

I'm actively looking for feedback on the API design and reliability. You can check out the repository, run the examples, and let me know what you think!

https://github.com/BenSiv/luametry
