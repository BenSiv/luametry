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
# Use csg_manifold.a so luastatic infers luaopen_csg_manifold
ar rcs obj/csg_manifold.a obj/csg_manifold.o

echo "Preparing Lua sources..."
# Copy to root to ensure module names 'cad', 'shapes' etc. are correct in bundled setup
# (Wait, if we run in root, we can just point luastatic to src/?)
# luastatic takes files. If we pass 'src/cad.lua', module name is 'src.cad'?
# static.lua: info.basename = ... info.dotpath = ...
# If path is src/cad.lua, dotpath is src.cad. 
# Our code requires "cad", not "src.cad".
# So copying to root (cwd) IS necessary for luastatic to name them "cad", "shapes".
cp src/cad.lua .
cp src/shapes.lua .
cp src/stl.lua .
cp obj/csg_manifold.a ./csg_manifold.a

echo "Generating static binary with luastatic..."
# luastatic arguments: main_script [lua_scripts] [static_libs] [includes/cflags/ldflags]
# We pass CC=g++ to handle C++ linking requirements
export CC=g++
luam $LUAM_DIR/lib/static/static.lua entry.lua cad.lua shapes.lua stl.lua csg_manifold.a $LIB_LUA $INC_LUA $LIB_MANIFOLD_FLAGS $LIBS

echo "Finalizing..."
mv entry $PROJECT

echo "Cleanup..."
rm cad.lua shapes.lua stl.lua csg_manifold.a entry.static.c

echo "Build complete."
ls -l $PROJECT
