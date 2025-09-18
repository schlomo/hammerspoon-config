#!/bin/bash

# --- Complete Hardware-Accelerated Transcode & Proxy Script (Single-Pass) ---
#
# This script performs an efficient, single-pass process to prepare footage
# for Kdenlive, creating both a high-quality intermediate file and a proxy file
# that can be automatically detected by Kdenlive.
#
# This method is significantly faster and more efficient as it eliminates
# the need to save and re-read the large intermediate file.
#
# Usage:
# 1. Save this file as `prepare_footage.sh`.
# 2. Make it executable: chmod +x prepare_footage.sh
# 3. Run with your video file: ./prepare_footage.sh your_video.mp4

# --- Configuration ---

# --- Edit-Friendly File Settings ---
BITRATE_MULTIPLIER="2.5"
EDIT_FRIENDLY_FORMAT="mov"

# --- Proxy File Settings ---
PROXY_SUFFIX=".proxy" # Suffix to add to the base filename for the proxy.
PROXY_FORMAT="mp4"
PROXY_WIDTH="960" # Resolution for the proxy file (width).
PROXY_BITRATE="2000k" # Target bitrate for the proxy file (e.g., 2000k = 2 Mbps).


# --- Script Logic ---
echo "--- Starting Footage Preparation (Single-Pass for Kdenlive Auto-Detect) ---"

# Check dependencies
if [ -z "$1" ]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi
if [ ! -f "$1" ]; then
  echo "Error: Input file '$1' not found."
  exit 1
fi
if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null || ! command -v bc &> /dev/null || ! command -v du &> /dev/null; then
    echo "Error: A required command (ffmpeg, ffprobe, bc, du) is not installed."
    echo "Please install them. On macOS with Homebrew: brew install ffmpeg bc"
    exit 1
fi

INPUT_FILE="$1"
FILENAME_NOEXT=$(basename -- "${INPUT_FILE%.*}")
EDIT_FRIENDLY_FILE="${FILENAME_NOEXT}.${EDIT_FRIENDLY_FORMAT}"
PROXY_FILE="${FILENAME_NOEXT}${PROXY_SUFFIX}.${PROXY_FORMAT}"

# --- Get Source Properties ---
FRAME_RATE=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
SOURCE_BITRATE=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")

if [ -z "$SOURCE_BITRATE" ] || [ "$SOURCE_BITRATE" = "N/A" ]; then
  SOURCE_BITRATE=$(ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
fi
if [ -z "$FRAME_RATE" ] || [ -z "$SOURCE_BITRATE" ] || [ "$SOURCE_BITRATE" = "N/A" ]; then
    echo "Error: Could not determine frame rate or bitrate of '$INPUT_FILE'."
    exit 1
fi

TARGET_BITRATE=$(printf "%.0f\n" $(echo "$SOURCE_BITRATE * $BITRATE_MULTIPLIER" | bc))

echo "Input: $INPUT_FILE"
echo "Target Bitrate for Edit-Friendly File: $((TARGET_BITRATE/1000)) kb/s"
echo "Target Bitrate for Proxy File: $PROXY_BITRATE"
echo "--------------------------------------------------"

# --- Single FFMPEG Command for Both Outputs ---
# This command decodes the input once, then uses a complex filtergraph to split
# the video stream and encode two separate outputs.

ffmpeg -y -hide_banner \
    -hwaccel videotoolbox -i "$INPUT_FILE" \
    -filter_complex "[0:v]split=2[v_edit][v_proxy_in]; [v_proxy_in]scale=${PROXY_WIDTH}:-2[v_proxy_out]" \
    \
    -map "[v_edit]" -map 0:a \
    -c:v hevc_videotoolbox -tag:v hvc1 -r "$FRAME_RATE" -b:v "$TARGET_BITRATE" -g 1 -pix_fmt p010le \
    -c:a copy \
    "$EDIT_FRIENDLY_FILE" \
    \
    -map "[v_proxy_out]" -map 0:a \
    -c:v h264_videotoolbox -r "$FRAME_RATE" -b:v "$PROXY_BITRATE" -g 1 \
    -c:a copy \
    "$PROXY_FILE"

if [ $? -ne 0 ]; then
  echo "Error: The single-pass ffmpeg command failed."
  [ -f "$EDIT_FRIENDLY_FILE" ] && rm "$EDIT_FRIENDLY_FILE"
  [ -f "$PROXY_FILE" ] && rm "$PROXY_FILE"
  exit 1
else
  echo "--- Footage Preparation Complete ---"
  echo "Edit-Friendly File: $EDIT_FRIENDLY_FILE"
  echo "Proxy File:         $PROXY_FILE"
  
  echo ""
  echo "--- File Sizes ---"
  SOURCE_SIZE=$(du -h "$INPUT_FILE" | awk '{print $1}')
  EDIT_FRIENDLY_SIZE=$(du -h "$EDIT_FRIENDLY_FILE" | awk '{print $1}')
  PROXY_SIZE=$(du -h "$PROXY_FILE" | awk '{print $1}')

  echo "Source File:          $SOURCE_SIZE"
  echo "Edit-Friendly File:   $EDIT_FRIENDLY_SIZE"
  echo "Proxy File:           $PROXY_SIZE"
fi

