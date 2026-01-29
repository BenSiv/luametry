#!/bin/bash

# Luametry CLI Demo
# Uses demo-magic: https://github.com/paxtonhare/demo-magic

# Source demo-magic from the user's home directory
source ~/Projects/demo-magic/demo-magic.sh

# Configure the prompt
DEMO_PROMPT="${GREEN}➜ ${CYAN}luametry ${COLOR_RESET}"

# Speed of typing
TYPE_SPEED=20

# Helper function for comments
function comment() {
  cmd=$DEMO_COMMENT_COLOR$1$COLOR_RESET
  echo -en "$cmd"; echo ""
}

clear

comment "# Welcome to the Luametry Demo"
comment "# A programmatic CAD tool for developers."
sleep 1

comment "# let's check the help command"
pe "bin/luametry --help"

comment "# Let's look at a simple example script: hex_bolt_simple.lua"
pe "micro tst/examples/hex_bolt_simple.lua"

comment "# Now, let's run this script to generate the 3D model"
pe "bin/luametry run tst/examples/hex_bolt_simple.lua"

comment "# Verification: Check the output STL file"
pe "ls -lh out/hex_bolt_simple.stl"

comment "# That's it! Fast, programmatic CAD."
