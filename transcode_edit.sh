#!/bin/bash

# --- Hardware-Accelerated Video Transcoding Script for Kdenlive on Apple Silicon ---
#
# This script transcodes a video file to a high-quality, edit-friendly, I-frame only
# HEVC format using FFmpeg and Apple's VideoToolbox. It's designed to create a
# visually lossless intermediate file for professional editing workflows.
#
# It automatically detects source bitrate and frame rate, increases the bitrate to
# compensate for the less efficient All-I compression, preserves 10-bit HDR color,
# and includes robust error handling.
#
# Usage:
# 1. Save this file as `transcode_edit.sh`.
# 2. Make it executable by running: chmod +x transcode_edit.sh
# 3. Run it with your video file as an argument: ./transcode_edit.sh your_video.mp4
#
# The output will be a new file named `your_video_edit_friendly.mov`.

# --- Configuration ---

# This multiplier increases the source bitrate to compensate for the lower efficiency
# of All-I compression, ensuring a visually lossless transcode.
# A value of 2.5 (a 150% increase) is a strong, safe default.
# Professional workflows often use multipliers between 2.0 and 4.0.
BITRATE_MULTIPLIER="2.5"

# The suffix to add to the output filename.
OUTPUT_SUFFIX="_edit_friendly"

# The container format for the output file. .mov is a good choice for editing.
OUTPUT_FORMAT="mov"


# --- Script Logic ---

# Check if an input file was provided.
if [ -z "$1" ];
  then
  echo "Usage: $0 <input_file>"
  exit 1
fi

# Check if the input file exists.
if [ ! -f "$1" ]; then
  echo "Error: Input file '$1' not found."
  exit 1
fi

# Check if ffmpeg, ffprobe, and bc are installed.
if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null || ! command -v bc &> /dev/null; then
    echo "Error: ffmpeg, ffprobe, or bc is not installed."
    echo "Please install them. On macOS with Homebrew: brew install ffmpeg bc"
    exit 1
fi


INPUT_FILE="$1"

# --- Dynamic Bitrate and Frame Rate Detection ---

# Get the frame rate of the input video to ensure it's preserved.
FRAME_RATE=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
if [ -z "$FRAME_RATE" ]; then
    echo "Error: Could not determine frame rate of '$INPUT_FILE'."
    exit 1
fi

# Get the video stream's bitrate from the source file.
SOURCE_BITRATE=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")

# If the stream bitrate is not available, fall back to the format bitrate.
if [ -z "$SOURCE_BITRATE" ] || [ "$SOURCE_BITRATE" = "N/A" ]; then
  echo "Stream bitrate not found, falling back to format bitrate."
  SOURCE_BITRATE=$(ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE")
fi

# If bitrate is still not available, exit with an error.
if [ -z "$SOURCE_BITRATE" ] || [ "$SOURCE_BITRATE" = "N/A" ]; then
  echo "Error: Could not determine source bitrate. Cannot proceed."
  exit 1
fi

# Calculate the new target bitrate using the multiplier.
# We use 'bc' for floating point multiplication and printf to get an integer result.
TARGET_BITRATE=$(printf "%.0f\n" $(echo "$SOURCE_BITRATE * $BITRATE_MULTIPLIER" | bc))

FILENAME=$(basename -- "$INPUT_FILE")
EXTENSION="${FILENAME##*.}"
FILENAME_NOEXT="${FILENAME%.*}"
OUTPUT_FILE="${FILENAME_NOEXT}${OUTPUT_SUFFIX}.${OUTPUT_FORMAT}"

echo "Input file: $INPUT_FILE"
echo "Detected frame rate: $FRAME_RATE"
echo "Source bitrate: $((SOURCE_BITRATE/1000)) kb/s"
echo "Target bitrate (x${BITRATE_MULTIPLIER}): $((TARGET_BITRATE/1000)) kb/s"
echo "Output will be saved as: $OUTPUT_FILE"
echo "--------------------------------------------------"

# Run the ffmpeg command with hardware acceleration for both decoding and encoding.
# Explanation of flags:
#
# -hwaccel videotoolbox   : Enable hardware acceleration for decoding the input file.
# -c:v hevc_videotoolbox  : Use Apple's hardware-accelerated HEVC (H.265) encoder.
# -tag:v hvc1             : Adds a tag to ensure compatibility with Apple's ecosystem.
# -r "$FRAME_RATE"        : Preserve the original frame rate.
# -b:v $TARGET_BITRATE    : Set the video bitrate (dynamically calculated).
# -g 1                    : Create an I-frame only (All-I) file for smooth seeking.
# -pix_fmt p010le         : Use a 10-bit pixel format to preserve HDR color.
# -c:a copy               : Copy audio without re-encoding to preserve quality.

ffmpeg -y -hide_banner \
       -hwaccel videotoolbox \
       -i "$INPUT_FILE" \
       -c:v hevc_videotoolbox \
       -tag:v hvc1 \
       -r "$FRAME_RATE" \
       -b:v "$TARGET_BITRATE" \
       -g 1 \
       -pix_fmt p010le \
       -c:a copy \
       "$OUTPUT_FILE"

# --- Error Handling ---
# Check the exit code of the ffmpeg command.
if [ $? -ne 0 ]; then
  echo "--------------------------------------------------"
  echo "Error: ffmpeg failed to transcode the file."
  if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
    echo "Removed incomplete output file: $OUTPUT_FILE"
  fi
  exit 1
else
  echo "--------------------------------------------------"
  echo "Transcoding complete!"
  echo "Your edit-friendly file is ready: $OUTPUT_FILE"
fi

