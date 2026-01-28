#!/bin/bash
# bld/test.sh
# Run the Luametry test suite

# Ensure we are in the project root
cd "$(dirname "$0")/.."

./bin/luametry run tst/run_all.lua
