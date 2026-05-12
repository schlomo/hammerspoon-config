#!/usr/bin/env python3

from __future__ import annotations

import argparse
import tempfile
from pathlib import Path

from media_common import ensure_files_exist, require_tools, run, human_size


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Concatenate WAV files gaplessly without re-encoding."
    )
    parser.add_argument("inputs", nargs="+", type=Path, help="Input WAV files in order")
    return parser.parse_args()


def ffmpeg_concat_demuxer_list_line(path: Path) -> str:
    escaped = str(path.resolve()).replace("'", r"'\''")
    return f"file '{escaped}'\n"


def main() -> None:
    args = parse_args()
    require_tools("ffmpeg")
    ensure_files_exist(args.inputs)

    first = args.inputs[0]
    output = first.parent / f"{first.stem}_concatenated_edit.wav"

    print("--- Starting WAV Gapless Concatenate ---")
    print("Input files:")
    for item in args.inputs:
        print(f"  - {item}")
    print(f"Output file: {output}")
    print("Audio mode: copy (no re-encode)")
    print("--------------------------------------------------")

    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            list_path = Path(tmpdir) / "concat-list.txt"
            with list_path.open("w", encoding="utf-8") as handle:
                for input_path in args.inputs:
                    handle.write(ffmpeg_concat_demuxer_list_line(input_path))

            run(
                [
                    "ffmpeg",
                    "-y",
                    "-hide_banner",
                    "-f",
                    "concat",
                    "-safe",
                    "0",
                    "-i",
                    list_path,
                    "-vn",
                    "-c:a",
                    "copy",
                    output,
                ]
            )
    except Exception:
        if output.exists():
            output.unlink()
        raise

    print("--- Complete ---")
    print(f"Created: {output} {human_size(output)}")


if __name__ == "__main__":
    main()
