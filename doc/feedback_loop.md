# Semantic Feedback Loop

The **Semantic Feedback Loop** is a set of features designed to improve the collaboration between AI agents and human designers in Luametry. It bridge the gap between 3D visual output and the source code that generates it.

## Key Features

### 1. Automatic Source Tracking
Every shape and operation in Luametry now automatically captures its location in the source code (filename and line number). This metadata is preserved throughout the scene graph.

### 2. Auto-Inferred Naming
Luametry automatically labels components based on the variable they are assigned to. This means you get descriptive manifests without any extra effort!

```lua
const cad = require("cad")
stern = cad.cube(10) -- Automatically labeled "stern"
```

You can still explicitly override this using the `cad.name` function if needed:
```lua
head = cad.name(cad.cube(5), "bolt_head")
```

### 3. Automated Manifest Generation
Whenever you run or export a script, Luametry automatically generates a `.manifest.json` file alongside the output. This file contains the complete scene graph with all names and source attributions.

**Example Manifest Snippet:**
```json
{
  "type": "op",
  "op": "union",
  "label": "final_assembly",
  "source_info": { "source": "my_script.lua", "line": 42 },
  "children": [...]
}
```

### 4. Model Analysis Tool
A new `analyze` command is available to quickly inspect the structure of a model from the terminal.

```bash
luametry analyze tst/examples/hex_bolt_simple.lua
```

## How it helps AI Agents
When a model isn't "quite right," the AI agent can:
1.  **Analyze the structure** to see how the model is put together.
2.  **Refer to the manifest** to find the exact line of code responsible for a specific shape.
3.  **Use human-provided names** (labels) to understand the semantic meaning of different parts.
