#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

RUN_TESTS=false
BUILD_ARGS=()
for arg in "$@"; do
    if [ "$arg" = "--test" ]; then
        RUN_TESTS=true
    else
        BUILD_ARGS+=("$arg")
    fi
done

if [ -z "${LUAM_DIR:-}" ]; then
    if [ -d "../luam" ]; then
        LUAM_DIR="$(cd ../luam && pwd)"
    else
        LUAM_DIR="$HOME/Projects/luam"
    fi
fi

if [ -z "${MANIFOLD_DIR:-}" ]; then
    if [ -d "../external/manifold" ]; then
        MANIFOLD_DIR="$(cd ../external/manifold && pwd)"
    elif [ -d "$HOME/projects/external/manifold" ]; then
        MANIFOLD_DIR="$HOME/projects/external/manifold"
    else
        MANIFOLD_DIR="$HOME/Projects/external/manifold"
    fi
fi

if [ -z "${MANIFOLD_CFLAGS:-}" ] || [ -z "${MANIFOLD_LDFLAGS:-}" ]; then
    if [ ! -f "$MANIFOLD_DIR/bindings/c/include/manifold/manifoldc.h" ]; then
        echo "Error: MANIFOLD_DIR ($MANIFOLD_DIR) missing bindings/c/include/manifold/manifoldc.h" >&2
        exit 1
    fi
    export MANIFOLD_CFLAGS="${MANIFOLD_CFLAGS:--I$MANIFOLD_DIR/bindings/c/include}"
    export MANIFOLD_LDFLAGS="${MANIFOLD_LDFLAGS:--L$MANIFOLD_DIR/build/src -L$MANIFOLD_DIR/build/bindings/c -lmanifoldc -lmanifold -Wl,-rpath,$MANIFOLD_DIR/build/src:$MANIFOLD_DIR/build/bindings/c}"
fi

"$LUAM_DIR/bin/luam" "$LUAM_DIR/lib/static/build.lua" --luamdir "$LUAM_DIR" "${BUILD_ARGS[@]}"

if [ "$RUN_TESTS" = true ]; then
    exec bash bld/test.sh
fi
