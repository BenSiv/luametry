#!/bin/bash
set -e

# Change to project root (one level up from bld/)
cd "$(dirname "$0")/.."

PROJECT="luametry"

# Flags
RUN_TESTS=false
for arg in "$@"; do
    if [ "$arg" == "--test" ]; then
        RUN_TESTS=true
    fi
done

# Resolve dependency paths (allow env overrides)
if [ -z "$LUAM_DIR" ]; then
    LUAM_DIR="$HOME/Projects/luam"
fi

if [ -z "$MANIFOLD_DIR" ]; then
    MANIFOLD_DIR="$HOME/Projects/manifold"
fi

if [ -z "$LFS_DIR" ]; then
    LFS_DIR="$LUAM_DIR/lib/lfs"
fi

if [ -z "$LUAM_DIR" ] || [ ! -f "$LUAM_DIR/src/lauxlib.h" ]; then
    echo "Error: LUAM_DIR not set or lauxlib.h not found. Set LUAM_DIR to your luam checkout." >&2
    exit 1
fi

if [ -z "$MANIFOLD_DIR" ] || [ ! -f "$MANIFOLD_DIR/bindings/c/include/manifold/manifoldc.h" ]; then
    echo "Error: MANIFOLD_DIR not set or manifold headers not found. Set MANIFOLD_DIR or build manifold." >&2
    exit 1
fi

if [ -z "$LFS_DIR" ] || [ ! -f "$LFS_DIR/src/lfs.c" ]; then
    echo "Error: LFS_DIR not set or lfs.c not found. Set LFS_DIR to your luafilesystem checkout." >&2
    exit 1
fi

# Include paths
INC_LUA="-I$LUAM_DIR/src"
INC_MANIFOLD="-I$MANIFOLD_DIR/bindings/c/include"

# Lib paths
LIB_LUA="$LUAM_DIR/obj/liblua.a"
LIB_MANIFOLD_FLAGS="-L$MANIFOLD_DIR/build/src -L$MANIFOLD_DIR/build/bindings/c -lmanifoldc -lmanifold -Wl,-rpath,$MANIFOLD_DIR/build/src:$MANIFOLD_DIR/build/bindings/c"

# System libs
LIBS="-ldl -lm -lstdc++"

echo "Compiling csg_manifold extension"
mkdir -p obj
g++ -c -O2 src/csg_manifold.cpp $INC_LUA $INC_MANIFOLD -o obj/csg_manifold.o
ar rcs obj/csg_manifold.a obj/csg_manifold.o

echo "Compiling lfs extension (static)"
cc -c -O2 -fPIC $INC_LUA "$LFS_DIR/src/lfs.c" -o obj/lfs.o
ar rcs obj/lfs.a obj/lfs.o

echo "Preparing Lua sources"
# Copy sources to root for correct module naming
cp src/cad.lua .
cp src/shapes.lua .
cp src/stl.lua .
cp src/step.lua .
cp src/obj.lua .
cp src/threemf.lua .
cp src/font.lua .
cp src/cli.lua .

# Copy lib/ subdirectory (argparse and deps)
mkdir -p lib
cp src/lib/*.lua lib/

cp obj/csg_manifold.a ./csg_manifold.a
cp obj/lfs.a ./lfs.a

echo "Generating static binary with luastatic"
export CC=g++
luam $LUAM_DIR/lib/static/static.lua entry.lua cad.lua shapes.lua stl.lua step.lua obj.lua threemf.lua font.lua cli.lua \
    lib/argparse.lua lib/utils.lua lib/dataframes.lua lib/string_utils.lua lib/table_utils.lua \
    csg_manifold.a lfs.a $LIB_LUA $INC_LUA $LIB_MANIFOLD_FLAGS $LIBS

echo "Finalizing"
mkdir -p bin && mv entry bin/$PROJECT

echo "Cleanup"
rm -f cad.lua shapes.lua stl.lua step.lua obj.lua threemf.lua font.lua cli.lua csg_manifold.a lfs.a entry.static.c
rm -rf lib/

echo "Build complete."
ls -l bin/$PROJECT

if [ "$RUN_TESTS" = true ]; then
    echo "Running tests..."
    bash bld/test.sh
fi
