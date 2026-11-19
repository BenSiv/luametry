#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -x "./bin/luametry" ]; then
    echo "Building bin/luametry..."
    ./bld/build.sh
fi

exec ./bin/luametry run tst/run_all.lua
