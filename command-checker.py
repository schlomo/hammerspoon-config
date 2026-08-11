#!/usr/bin/env python3
"""Repeatedly run a command and log each invocation to CSV."""

from __future__ import annotations

import csv
import os
import random
import shlex
import subprocess
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path


def format_timestamp(when: datetime) -> str:
    return when.strftime("%Y-%m-%d %H:%M:%S")


def format_elapsed(seconds: float) -> str:
    total = int(seconds)
    hours, rem = divmod(total, 3600)
    minutes, secs = divmod(rem, 60)
    return f"{hours:02d}:{minutes:02d}:{secs:02d}"


@dataclass
class RunStats:
    successes: int = 0
    failures: int = 0
    durations: list[float] = field(default_factory=list)
    started_at: float = field(default_factory=time.monotonic)
    next_run_at: float | None = None

    def record(self, *, success: bool, duration: float) -> None:
        if success:
            self.successes += 1
        else:
            self.failures += 1
        self.durations.append(duration)

    def format_status(self) -> str:
        elapsed = time.monotonic() - self.started_at
        total = self.successes + self.failures
        if self.durations:
            min_d, max_d = min(self.durations), max(self.durations)
            avg_d = sum(self.durations) / len(self.durations)
            timing = f"cmd {min_d:.2f}/{avg_d:.2f}/{max_d:.2f}s min/avg/max"
        else:
            timing = "cmd —/—/—s min/avg/max"
        countdown = ""
        if self.next_run_at is not None:
            remaining = max(0.0, self.next_run_at - time.monotonic())
            countdown = f" | next in {remaining:.0f}s"
        return (
            f"runs {total} | ok {self.successes} fail {self.failures} | "
            f"elapsed {format_elapsed(elapsed)} | {timing}{countdown}"
        )


class CommandChecker:
    def __init__(self, command: list[str], output_path: Path) -> None:
        self.command = command
        self.command_text = shlex.join(command)
        self.output_path = output_path
        self.stats = RunStats()

    def run_once(self) -> tuple[bool, float, str]:
        self.stats.next_run_at = None
        started = time.monotonic()
        try:
            result = subprocess.run(
                self.command_text,
                shell=True,
                executable=os.environ.get("SHELL", "/bin/bash"),
                capture_output=True,
                text=True,
            )
        except OSError as exc:
            duration = time.monotonic() - started
            return False, duration, str(exc)

        duration = time.monotonic() - started
        output = result.stdout
        if result.stderr:
            output = f"{output}\n--- stderr ---\n{result.stderr}" if output else result.stderr
        return result.returncode == 0, duration, output.rstrip("\n")

    def append_row(self, writer: csv.writer, *, success: bool, duration: float, output: str) -> None:
        writer.writerow(
            [
                format_timestamp(datetime.now()),
                self.command_text,
                "success" if success else "failure",
                round(duration, 3),
                output,
            ]
        )

    def refresh_status(self) -> None:
        sys.stdout.write(f"\r\033[K{self.stats.format_status()}\r")
        sys.stdout.flush()

    def clear_status(self) -> None:
        sys.stdout.write("\r\033[K")
        sys.stdout.flush()

    def run(self) -> None:
        print(f"Logging to {self.output_path}")
        print(f"Command: {self.command_text}")
        print("Ctrl+C to stop.\n")

        with self.output_path.open("w", encoding="utf-8-sig", newline="") as handle:
            writer = csv.writer(
                handle,
                quoting=csv.QUOTE_NONNUMERIC,
                lineterminator="\n",
            )
            writer.writerow(["timestamp", "command", "status", "duration_s", "output"])

            try:
                while True:
                    success, duration, output = self.run_once()
                    self.stats.record(success=success, duration=duration)
                    self.append_row(writer, success=success, duration=duration, output=output)
                    handle.flush()
                    self.refresh_status()

                    delay = random.uniform(5, 30)
                    deadline = time.monotonic() + delay
                    self.stats.next_run_at = deadline
                    while time.monotonic() < deadline:
                        self.refresh_status()
                        time.sleep(min(0.5, deadline - time.monotonic()))
            except KeyboardInterrupt:
                self.clear_status()
                self.stats.next_run_at = None

        print(self.stats.format_status())
        print(f"Wrote {self.output_path}")


USAGE = f"""\
usage: {Path(__file__).name} [-h] COMMAND [ARGS ...]

{__doc__.strip()}

Example:
  {Path(__file__).name} echo -e "foo\\n\\tbar\\nblub,,\\"'\\n"
"""


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else list(argv)

    if not argv or argv in (["-h"], ["--help"]):
        print(USAGE, end="")
        return 0 if argv else 2

    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    me = Path(__file__)
    stem = me.stem
    output_path = Path(f"{stem}-{argv[0]}-{stamp}.csv").resolve()
    CommandChecker(argv, output_path).run()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
