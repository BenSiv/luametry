#!/bin/bash
set -e

# Change to project root (one level up from bld/)
cd "$(dirname "$0")/.."

PROJECT="luametry"
LUAM_DIR="/home/bensiv/Projects/luam"
MANIFOLD_DIR="/home/bensiv/Projects/manifold"

# Include paths
INC_LUA="-I$LUAM_DIR/src"
INC_MANIFOLD="-I$MANIFOLD_DIR/bindings/c/include"

# Lib paths
LIB_LUA="$LUAM_DIR/obj/liblua.a"
LIB_MANIFOLD_FLAGS="-L$MANIFOLD_DIR/build/src -L$MANIFOLD_DIR/build/bindings/c -lmanifoldc -lmanifold -Wl,-rpath,$MANIFOLD_DIR/build/src:$MANIFOLD_DIR/build/bindings/c"

# System libs
LIBS="-ldl -lm -lstdc++"

echo "Compiling csg_manifold extension..."
mkdir -p obj
g++ -c -O2 src/csg_manifold.cpp $INC_LUA $INC_MANIFOLD -o obj/csg_manifold.o
ar rcs obj/csg_manifold.a obj/csg_manifold.o

echo "Preparing Lua sources..."
# Copy sources to root for correct module naming
cp src/cad.lua .
cp src/shapes.lua .
cp src/stl.lua .
cp src/cli.lua .

# Copy lib/ subdirectory (argparse and deps)
mkdir -p lib
cp src/lib/*.lua lib/

cp obj/csg_manifold.a ./csg_manifold.a

echo "Generating static binary with luastatic..."
export CC=g++
luam $LUAM_DIR/lib/static/static.lua entry.lua cad.lua shapes.lua stl.lua cli.lua \
    lib/argparse.lua lib/utils.lua lib/dataframes.lua lib/string_utils.lua lib/table_utils.lua \
    csg_manifold.a $LIB_LUA $INC_LUA $LIB_MANIFOLD_FLAGS $LIBS

echo "Finalizing..."
mkdir -p bin && mv entry bin/$PROJECT

echo "Cleanup..."
rm -f cad.lua shapes.lua stl.lua cli.lua csg_manifold.a entry.static.c
rm -rf lib/

echo "Build complete."
ls -l bin/$PROJECT
