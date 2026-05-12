#!/bin/bash

# --- Extract All Audio Tracks and Channels ---
#
# Takes a video (or media) file and exports one mono WAV file per channel
# for every audio track using lossless PCM (pcm_s24le).
#
# Usage:
#   ./extract_audio_channels.sh input_video_file

set -u

echo "--- Starting Audio Track/Channel Extraction ---"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <input_video_file>"
  exit 1
fi

INPUT_FILE="$1"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: Input file '$INPUT_FILE' not found."
  exit 1
fi

if ! command -v ffmpeg > /dev/null 2>&1 || ! command -v ffprobe > /dev/null 2>&1; then
  echo "Error: Required commands (ffmpeg, ffprobe) are not installed."
  echo "Install on macOS with Homebrew: brew install ffmpeg"
  exit 1
fi

BASE_DIR=$(dirname -- "$INPUT_FILE")
BASE_NAME=$(basename -- "${INPUT_FILE%.*}")
OUTPUT_EXT="wav"
OUTPUT_CODEC="pcm_s24le"

channel_label() {
  local layout="$1"
  local channels="$2"
  local index="$3"

  if [ "$channels" = "1" ]; then
    echo "mono"
    return
  fi

  if [ "$layout" = "stereo" ] || [ "$layout" = "2 channels (FL+FR)" ]; then
    if [ "$index" -eq 0 ]; then
      echo "left"
    elif [ "$index" -eq 1 ]; then
      echo "right"
    else
      echo "ch$((index + 1))"
    fi
    return
  fi

  echo "ch$((index + 1))"
}

AUDIO_STREAM_INFO=$(ffprobe -v error -select_streams a -show_entries stream=index,codec_name,channels,channel_layout -of csv=p=0:s='|' "$INPUT_FILE")

if [ -z "$AUDIO_STREAM_INFO" ]; then
  echo "Error: Could not find any audio streams in '$INPUT_FILE'."
  exit 1
fi

echo "Input file: $INPUT_FILE"
echo "--------------------------------------------------"

TRACK_NUM=0
AUDIO_POS=0
FILTER_PARTS=()
CMD_OUTPUT_PARTS=()
EXPECTED_FILES=()

while IFS='|' read -r STREAM_INDEX AUDIO_CODEC CHANNEL_COUNT CHANNEL_LAYOUT; do
  [ -z "$STREAM_INDEX" ] && continue

  TRACK_NUM=$((TRACK_NUM + 1))
  AUDIO_POS_CURRENT=$AUDIO_POS
  AUDIO_POS=$((AUDIO_POS + 1))
  echo "Track $TRACK_NUM (stream index $STREAM_INDEX): source_codec=$AUDIO_CODEC channels=$CHANNEL_COUNT layout=${CHANNEL_LAYOUT:-unknown}"

  SPLIT_LABELS=()
  CH=0
  while [ "$CH" -lt "$CHANNEL_COUNT" ]; do
    SPLIT_LABELS+=("[t${TRACK_NUM}_split${CH}]")
    CH=$((CH + 1))
  done

  if [ "$CHANNEL_COUNT" -gt 1 ]; then
    FILTER_PARTS+=("[0:a:${AUDIO_POS_CURRENT}]asplit=${CHANNEL_COUNT}${SPLIT_LABELS[*]}")
  fi

  CH=0
  while [ "$CH" -lt "$CHANNEL_COUNT" ]; do
    LABEL=$(channel_label "${CHANNEL_LAYOUT:-}" "$CHANNEL_COUNT" "$CH")
    OUT_FILE="${BASE_DIR}/${BASE_NAME}_track${TRACK_NUM}_${LABEL}.${OUTPUT_EXT}"
    OUT_LABEL="[out_t${TRACK_NUM}_c${CH}]"

    if [ "$CHANNEL_COUNT" -eq 1 ]; then
      FILTER_PARTS+=("[0:a:${AUDIO_POS_CURRENT}]pan=mono|c0=c0${OUT_LABEL}")
    else
      FILTER_PARTS+=("[t${TRACK_NUM}_split${CH}]pan=mono|c0=c${CH}${OUT_LABEL}")
    fi

    CMD_OUTPUT_PARTS+=(
      "-map" "$OUT_LABEL"
      "-c:a" "$OUTPUT_CODEC"
      "-ac" "1"
      "-channel_layout" "mono"
      "$OUT_FILE"
    )
    EXPECTED_FILES+=("$OUT_FILE")
    echo "  - Created: $OUT_FILE"
    CH=$((CH + 1))
  done
done <<< "$AUDIO_STREAM_INFO"

if [ "${#FILTER_PARTS[@]}" -eq 0 ]; then
  echo "Error: No audio channels found to extract."
  exit 1
fi

FILTER_COMPLEX=$(IFS='; '; echo "${FILTER_PARTS[*]}")

ffmpeg -y -hide_banner \
  -i "$INPUT_FILE" \
  -filter_complex "$FILTER_COMPLEX" \
  "${CMD_OUTPUT_PARTS[@]}"

if [ $? -ne 0 ]; then
  echo "Error: ffmpeg extraction failed."
  for expected in "${EXPECTED_FILES[@]}"; do
    [ -f "$expected" ] && rm -f "$expected"
  done
  exit 1
fi

echo "--- Complete ---"
echo "Created ${#EXPECTED_FILES[@]} file(s)."
