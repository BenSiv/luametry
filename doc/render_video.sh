#!/bin/bash

# render_video.sh
# A simple bash script to compose a 'talking head' video over a 'screen recording'.
# Dependencies: ffmpeg

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <screen_video> <face_video> <output_video> [start_time_seconds]"
    echo "Example: $0 screen.mp4 face.mp4 output.mp4 5"
    exit 1
fi

SCREEN=$1
FACE=$2
OUTPUT=$3
START_TIME=${4:-0} # Default to 0 if not provided

# Configuration
# Scale of the face video relative to original (divisor). 4 means 1/4th size.
SCALE_DIVISOR=4
# Padding from the bottom right corner
PADDING=20

echo "Rendering video..."
echo "Screen: $SCREEN"
echo "Face:   $FACE (Starting at ${START_TIME}s)"
echo "Output: $OUTPUT"

# FFmpeg Filter Explanation:
# [1:v]scale=iw/$SCALE_DIVISOR:-1[face] 
#   -> Take the 2nd input (face), scale it down.
# [0:v][face]overlay=W-w-$PADDING:H-h-$PADDING:enable='gte(t,$START_TIME)' 
#   -> Overlay 'face' on '0:v' (screen).
#   -> X position: Width - width - padding (Right align)
#   -> Y position: Height - height - padding (Bottom align)
#   -> enable: Only show after START_TIME

ffmpeg -y \
    -i "$SCREEN" \
    -i "$FACE" \
    -filter_complex \
    "[1:v]scale=iw/$SCALE_DIVISOR:-1[face]; \
     [0:v][face]overlay=main_w-overlay_w-$PADDING:main_h-overlay_h-$PADDING:enable='gte(t,$START_TIME)'" \
    -c:a copy \
    "$OUTPUT"

echo "Done! Saved to $OUTPUT"
