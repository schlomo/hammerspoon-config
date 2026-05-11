#!/bin/bash

# --- Concatenate WAV Files (Gapless, No Re-Encode) ---
#
# Concatenates input WAV files in the given order without re-encoding
# audio (`-c:a copy`) for maximum quality retention and speed.
#
# Usage:
#   ./concatenate_wav.sh file1.wav file2.wav [file3.wav ...]

set -u

OUTPUT_SUFFIX="_concatenated_edit"
OUTPUT_FORMAT="wav"
OUTPUT_MODE="copy"

echo "--- Starting WAV Gapless Concatenate ---"

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <input1.wav> [input2.wav ...]"
  exit 1
fi

if ! command -v ffmpeg > /dev/null 2>&1; then
  echo "Error: ffmpeg is not installed."
  echo "Install on macOS with Homebrew: brew install ffmpeg"
  exit 1
fi

for input in "$@"; do
  if [ ! -f "$input" ]; then
    echo "Error: Input file '$input' not found."
    exit 1
  fi
done

FIRST_INPUT="$1"
FIRST_DIR=$(dirname -- "$FIRST_INPUT")
FIRST_BASE=$(basename -- "${FIRST_INPUT%.*}")
OUTPUT_FILE="${FIRST_DIR}/${FIRST_BASE}${OUTPUT_SUFFIX}.${OUTPUT_FORMAT}"

TMP_LIST=$(mktemp)

cleanup() {
  [ -f "$TMP_LIST" ] && rm -f "$TMP_LIST"
}
trap cleanup EXIT

for input in "$@"; do
  ABS_PATH=$(cd "$(dirname -- "$input")" && pwd)/"$(basename -- "$input")"
  # ffmpeg concat list escaping: single quotes must be escaped as '\''.
  ESCAPED_PATH=$(printf "%s" "$ABS_PATH" | sed "s/'/'\\\\''/g")
  printf "file '%s'\n" "$ESCAPED_PATH" >> "$TMP_LIST"
done

echo "Input files:"
for input in "$@"; do
  echo "  - $input"
done
echo "Output file: $OUTPUT_FILE"
echo "Audio mode: $OUTPUT_MODE (no re-encode)"
echo "--------------------------------------------------"

ffmpeg -y -hide_banner \
  -f concat -safe 0 -i "$TMP_LIST" \
  -vn \
  -c:a copy \
  "$OUTPUT_FILE"

if [ $? -ne 0 ]; then
  echo "Error: ffmpeg concatenate failed."
  [ -f "$OUTPUT_FILE" ] && rm -f "$OUTPUT_FILE"
  exit 1
fi

echo "--- Complete ---"
echo "Created: $OUTPUT_FILE"
