# Luametry Showcase - Video Transcript

## 1. Introduction
**(Visual: Host on camera or screen recording of the terminal)**

"Hi everyone. I've been working on a project called **Luametry**, and I wanted to share the story behind why I built it."

"If you've done programmatic CAD, you've likely used OpenSCAD. It pioneered the space and is a fantastic tool. However, as a developer, I often found myself yearning for the features of a general-purpose programming language. Things like reading configuration files, handling command line arguments, and maintaining a clear separation between code and data."

## 2. The Journey
**(Visual: Diagram showing OpenSCAD Wrapper -> Manifol# Luametry Showcase - Video Transcript

## 1. Introduction
**(Visual: Host on camera or screen recording of the terminal)**

"Hi everyone. I've been working on a project called **Luametry**, and I wanted to share the story behind why I built it."

"If you've done programmatic CAD, you've likely used OpenSCAD. It pioneered the space and is a fantastic tool. However, as a developer, I often found myself yearning for the features of a general-purpose programming language. Things like reading configuration files, handling command line arguments, and maintaining a clear separation between code and data."

## 2. The Journey
**(Visual: Diagram showing OpenSCAD Wrapper -> Manifold Binding)**

"My journey actually started by writing a Lua library that simply wrapped OpenSCAD. I wanted that developer experience, but I was still generating OpenSCAD code under the hood."

"Eventually, I decided to cut out the middleman entirely. I chose **Manifold** as the underlying geometry kernel because of its incredible speed and robustness. It's the same modern kernel that OpenSCAD itself is now adopting as an alternative backend."

"So that's what **Luametry** is today: It binds a modern Lua dialect directly to the Manifold C++ kernel, giving you a high-performance, code-first CAD experience without the legacy baggage."

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

"It's not just for 3D printing either. While it defaults to STL, you can easily export to STEP for precision CAD work, OBJ for rendering pipelines, or 3MF. You can even generate PNG screenshots directly from the CLI."

"It's still early days, but if you're interested in a code-first approach to 3D modeling, check out the repository. I'm keen to hear your feedback on the API and what features you'd like to see next."
d Binding)**

"My journey actually started by writing a Lua library that simply wrapped OpenSCAD. I wanted that developer experience, but I was still generating OpenSCAD code under the hood."

"Eventually, I decided to cut out the middleman entirely. I chose **Manifold** as the underlying geometry kernel because of its incredible speed and robustness. It's the same modern kernel that OpenSCAD itself is now adopting as an alternative backend."

"So that's what **Luametry** is today: It binds a modern Lua dialect directly to the Manifold C++ kernel, giving you a high-performance, code-first CAD experience without the legacy baggage."

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
# Luametry Showcase - Video Transcript

## 1. Introduction
**(Visual: Host on camera or screen recording of the terminal)**

"Hi everyone. I've been working on a project called **Luametry**, and I wanted to share the story behind why I built it."

"If you've done programmatic CAD, you've likely used OpenSCAD. It pioneered the space and is a fantastic tool. However, as a developer, I often found myself yearning for the features of a general-purpose programming language. Things like reading configuration files, handling command line arguments, and maintaining a clear separation between code and data."

## 2. The Journey
**(Visual: Diagram showing OpenSCAD Wrapper -> Manifold Binding)**

"My journey actually started by writing a Lua library that simply wrapped OpenSCAD. I wanted that developer experience, but I was still generating OpenSCAD code under the hood."

"Eventually, I decided to cut out the middleman entirely. I chose **Manifold** as the underlying geometry kernel because of its incredible speed and robustness. It's the same modern kernel that OpenSCAD itself is now adopting as an alternative backend."

"So that's what **Luametry** is today: It binds a modern Lua dialect directly to the Manifold C++ kernel, giving you a high-performance, code-first CAD experience without the legacy baggage."

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

"It's not just for 3D printing either. While it defaults to STL, you can easily export to STEP for precision CAD work, OBJ for rendering pipelines, or 3MF. You can even generate PNG screenshots directly from the CLI."

"It's still early days, but if you're interested in a code-first approach to 3D modeling, check out the repository. I'm keen to hear your feedback on the API and what features you'd like to see next."

"Then, we just perform a boolean difference: Shaft minus Thread Cutter. Because Manifold is efficiently handling the geometry, this operation is near-instantaneous."

## 4. Closing
**(Visual: Terminal showing the CLI commands)**

"The project also includes a CLI with live reloading, so you can iterate on your designs quickly."

"It's not just for 3D printing either. While it defaults to STL, you can easily export to STEP for precision CAD work, OBJ for rendering pipelines, or 3MF. You can even generate PNG screenshots directly from the CLI."

"It's still early days, but if you're interested in a code-first approach to 3D modeling, check out the repository. I'm keen to hear your feedback on the API and what features you'd like to see next."
