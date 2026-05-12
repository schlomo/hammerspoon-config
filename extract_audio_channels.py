#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path

from media_common import ffprobe_json, require_tools, run

OUTPUT_EXT = "wav"
OUTPUT_CODEC = "pcm_s24le"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract one mono WAV per channel for all audio streams."
    )
    parser.add_argument("input", type=Path, help="Input media file")
    return parser.parse_args()


def channel_label(layout: str, channels: int, index: int) -> str:
    if channels == 1:
        return "mono"
    if layout in {"stereo", "2 channels (FL+FR)"}:
        if index == 0:
            return "left"
        if index == 1:
            return "right"
    return f"ch{index + 1}"


def main() -> None:
    args = parse_args()
    require_tools("ffmpeg", "ffprobe")

    input_file = args.input
    if not input_file.is_file():
        raise SystemExit(f"Error: input file not found: {input_file}")

    probe = ffprobe_json(input_file, stream_selector="a")
    streams = probe.get("streams", [])
    if not streams:
        raise SystemExit(f"Error: could not find audio streams in '{input_file}'.")

    print("--- Starting Audio Track/Channel Extraction ---")
    print(f"Input file: {input_file}")
    print("--------------------------------------------------")

    base_dir = input_file.parent
    base_name = input_file.stem
    filter_parts: list[str] = []
    output_parts: list[str | Path] = []
    expected_files: list[Path] = []

    for audio_pos, stream in enumerate(streams):
        track_num = audio_pos + 1
        channels = int(stream.get("channels") or 0)
        if channels < 1:
            continue
        layout = stream.get("channel_layout") or ""
        source_codec = stream.get("codec_name") or "unknown"
        print(
            "Track "
            f"{track_num}: source_codec={source_codec} "
            f"channels={channels} layout={layout or 'unknown'}"
        )

        if channels == 1:
            source_labels = [f"[0:a:{audio_pos}]"]
        else:
            source_labels = [f"[t{track_num}_split{ch}]" for ch in range(channels)]
            filter_parts.append(
                f"[0:a:{audio_pos}]asplit={channels}{''.join(source_labels)}"
            )

        for ch, source_label in enumerate(source_labels):
            label = channel_label(layout, channels, ch)
            out_file = base_dir / f"{base_name}_track{track_num}_{label}.{OUTPUT_EXT}"
            out_label = f"[out_t{track_num}_c{ch}]"
            filter_parts.append(f"{source_label}pan=mono|c0=c{ch}{out_label}")

            output_parts += [
                "-map",
                out_label,
                "-c:a",
                OUTPUT_CODEC,
                "-ac",
                "1",
                "-channel_layout",
                "mono",
                out_file,
            ]
            expected_files.append(out_file)
            print(f"  - Will create: {out_file}")

    if not filter_parts:
        raise SystemExit("Error: no audio channels found to extract.")

    filter_complex = "; ".join(filter_parts)
    cmd: list[str | Path] = [
        "ffmpeg",
        "-y",
        "-hide_banner",
        "-i",
        input_file,
        "-filter_complex",
        filter_complex,
        *output_parts,
    ]

    try:
        run(cmd)
    except Exception:
        for path in expected_files:
            if path.exists():
                path.unlink()
        raise

    print("--- Complete ---")
    print(f"Created {len(expected_files)} file(s).")


if __name__ == "__main__":
    main()
