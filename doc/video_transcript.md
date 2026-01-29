# Luametry Showcase - Video Transcript

## 1. Introduction
**(Visual: Host on camera or screen recording of the terminal)**

"Hi everyone. I've been working on a project called **Luametry**, and I wanted to walk you through why I built it and how it works."

"If you've done programmatic CAD, you've likely used OpenSCAD. It pioneered the space and is a fantastic tool. However, as a developer, I often found myself yearning for the features of a general-purpose programming language—things like local scoping, huge standard libraries, and proper modules. I wanted the flexibility to read configuration files, handle command line arguments, and maintain a clear separation between code and data."

## 2. The Solution: Luametry
**(Visual: Luametry Tech Stack Diagram / Terminal)**

"Luametry attempts to address these challenges by bringing a real programming language to 3D modeling."

"It runs on **Luam**, a modern dialect of Lua. It enforces local scoping by default, keeping the code simple and procedural, perfect for geometry pipelines."

"For the geometry engine, it uses **Manifold**, created by Emmett Lalish. It's a C++ kernel that's extremely fast and, most importantly, robust. It handles complex boolean operations that would typically crash or stall other engines, and it always produces watertight meshes."

## 3. Code Walkthrough: A Threaded Bolt
**(Visual: Split screen. Left: Code. Right: 3D View)**

"Let's look at a practical example: generating a threaded hex bolt. This showcases how we can use standard programming logic for CAD."

**(Visual: Highlight Head creation)**

"We start by requiring our standard libraries. Defining the head is a simple function call to `cad.create.cylinder`. We pass in a table of parameters—radius, height, segments."

**(Visual: Highlight Shaft creation)**

"The shaft is another cylinder. Because we're in Lua, we can easily manipulate these shapes. Here, we just translate the shaft downwards."

**(Visual: Highlight Thread logic)**

"Thread generation is where the CSG (Constructive Solid Geometry) capabilities really shine. We use the `shapes` library to create a negative thread shape—essentially a cutter defined by a helical profile."

**(Visual: Highlight Difference operation)**

"Then, we just perform a boolean difference: Shaft minus Thread Cutter. Because Manifold is efficiently handling the geometry, this operation is near-instantaneous."

## 4. Closing
**(Visual: Terminal showing the CLI commands)**

"The project also includes a CLI with live reloading, so you can iterate on your designs quickly."

"It's still early days, but if you're interested in a code-first approach to 3D modeling, check out the repository. I'm keen to hear your feedback on the API and what features you'd like to see next."
