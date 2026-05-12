#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path

from media_common import ffprobe_json, human_size, require_tools, run

BITRATE_MULTIPLIER = 2.5
EDIT_FRIENDLY_FORMAT = "mov"
PROXY_SUFFIX = ".proxy"
PROXY_FORMAT = "mp4"
PROXY_WIDTH = "960"
PROXY_BITRATE = "2000k"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create edit-friendly and proxy outputs in one ffmpeg pass."
    )
    parser.add_argument("input", type=Path, help="Input video file")
    return parser.parse_args()


def pick_video_stream(probe: dict) -> dict | None:
    for stream in probe.get("streams", []):
        if stream.get("r_frame_rate"):
            return stream
    return None


def parse_bitrate(probe: dict, stream: dict) -> int | None:
    for value in (stream.get("bit_rate"), probe.get("format", {}).get("bit_rate")):
        if value and value != "N/A":
            try:
                return int(value)
            except ValueError:
                pass
    return None


def main() -> None:
    args = parse_args()
    require_tools("ffmpeg", "ffprobe")

    input_file = args.input
    if not input_file.is_file():
        raise SystemExit(f"Error: input file not found: {input_file}")

    base_name = input_file.stem
    edit_friendly = Path(f"{base_name}.{EDIT_FRIENDLY_FORMAT}")
    proxy = Path(f"{base_name}{PROXY_SUFFIX}.{PROXY_FORMAT}")

    probe = ffprobe_json(input_file, stream_selector="v:0")
    video_stream = pick_video_stream(probe)
    if not video_stream:
        raise SystemExit(f"Error: no video stream found in '{input_file}'.")

    frame_rate = video_stream.get("r_frame_rate")
    source_bitrate = parse_bitrate(probe, video_stream)
    if not frame_rate or not source_bitrate:
        raise SystemExit(
            f"Error: could not determine frame rate/bitrate for '{input_file}'."
        )

    target_bitrate = round(source_bitrate * BITRATE_MULTIPLIER)

    print("--- Starting Footage Preparation (Single-Pass) ---")
    print(f"Input: {input_file}")
    print(f"Target bitrate (edit-friendly): {target_bitrate // 1000} kb/s")
    print(f"Target bitrate (proxy): {PROXY_BITRATE}")
    print("--------------------------------------------------")

    cmd: list[str | Path] = [
        "ffmpeg",
        "-y",
        "-hide_banner",
        "-hwaccel",
        "videotoolbox",
        "-i",
        input_file,
        "-filter_complex",
        f"[0:v]split=2[v_edit][v_proxy_in]; [v_proxy_in]scale={PROXY_WIDTH}:-2[v_proxy_out]",
        "-map",
        "[v_edit]",
        "-map",
        "0:a",
        "-c:v",
        "hevc_videotoolbox",
        "-tag:v",
        "hvc1",
        "-r",
        str(frame_rate),
        "-b:v",
        str(target_bitrate),
        "-g",
        "1",
        "-pix_fmt",
        "p010le",
        "-c:a",
        "copy",
        edit_friendly,
        "-map",
        "[v_proxy_out]",
        "-map",
        "0:a",
        "-c:v",
        "h264_videotoolbox",
        "-r",
        str(frame_rate),
        "-b:v",
        PROXY_BITRATE,
        "-g",
        "1",
        "-c:a",
        "copy",
        proxy,
    ]

    try:
        run(cmd)
    except Exception:
        if edit_friendly.exists():
            edit_friendly.unlink()
        if proxy.exists():
            proxy.unlink()
        raise

    print("--- Footage Preparation Complete ---")
    print(f"Edit-Friendly File: {edit_friendly}")
    print(f"Proxy File:         {proxy}")
    print("")
    print("--- File Sizes ---")
    print(f"Source File:          {human_size(input_file)}")
    print(f"Edit-Friendly File:   {human_size(edit_friendly)}")
    print(f"Proxy File:           {human_size(proxy)}")


if __name__ == "__main__":
    main()
