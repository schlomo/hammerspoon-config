#!/usr/bin/env python3

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Iterable, Sequence


def require_tools(*tools: str) -> None:
    missing = [tool for tool in tools if shutil.which(tool) is None]
    if missing:
        names = ", ".join(missing)
        raise SystemExit(
            f"Error: required command(s) not found: {names}\n"
            f"Install on macOS with Homebrew: brew install {names}"
        )


def run(
    cmd: Sequence[str | os.PathLike[str]],
    *,
    capture_output: bool = False,
    text: bool = True,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [os.fspath(part) for part in cmd],
        check=True,
        capture_output=capture_output,
        text=text,
    )


def ffprobe_json(input_file: Path, *, stream_selector: str | None = None) -> dict:
    cmd: list[str | os.PathLike[str]] = ["ffprobe", "-v", "error"]
    if stream_selector:
        cmd.extend(["-select_streams", stream_selector])
    cmd.extend(
        [
            "-show_entries",
            "stream=index,codec_name,channels,channel_layout,bit_rate,r_frame_rate:format=bit_rate",
            "-of",
            "json",
            input_file,
        ]
    )
    result = run(cmd, capture_output=True)
    return json.loads(result.stdout)


def ensure_files_exist(paths: Iterable[Path]) -> None:
    for path in paths:
        if not path.is_file():
            raise SystemExit(f"Error: input file not found: {path}")


def human_size(path: Path) -> str:
    size = path.stat().st_size
    units = ["B", "KB", "MB", "GB", "TB"]
    value = float(size)
    idx = 0
    while value >= 1024 and idx < len(units) - 1:
        value /= 1024
        idx += 1
    return f"{value:.1f}{units[idx]}"
