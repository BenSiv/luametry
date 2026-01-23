#!/bin/bash

# Ensure output directory exists and initial STL is built
if [ ! -f "out/benchy.stl" ]; then
    echo "Initial build..."
    luam tst/benchy.lua
fi

echo "Starting Live Preview..."
echo " - Watcher running in background (monitors src/ and tst/)"
echo " - F3D viewer running in foreground (auto-reloads on change)"
echo "Press Ctrl+C to stop both."

# Start watcher in background
luam tls/watch.lua &
WATCHER_PID=$!

# Start F3D viewer in foreground
# --up +Z: set Z as up axis (common for 3D print)
# Note: This version of f3d doesn't support --watch. Press 'Up Arrow' to reload.
echo "Tip: Press 'Up Arrow' in the F3D window to reload the model."
f3d out/benchy.stl --up +Z --resolution 1200,800

# Cleanup when F3D is closed
kill $WATCHER_PID
echo "Live Preview stopped."
