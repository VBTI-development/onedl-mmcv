#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


DEFAULT_MATRIX = Path("ci/build-matrix.json")


def load_group(path: Path, group_id: str) -> dict:
    config = json.loads(path.read_text())
    for group in config.get("build_groups", []):
        if group.get("id") == group_id:
            return group
    raise SystemExit(f"Unknown build group: {group_id}")


def install_args(group: dict, build_identifier: str) -> list[str]:
    try:
        spec = group["torch_by_build"][build_identifier]
    except KeyError as exc:
        valid = ", ".join(sorted(group["torch_by_build"]))
        raise SystemExit(
            f"{build_identifier!r} is not configured for {group['id']}; valid: {valid}"
        ) from exc

    packages = [f"torch=={spec['torch']}"]
    torchvision = spec.get("torchvision", "")
    packages.append(f"torchvision=={torchvision}" if torchvision else "torchvision")

    args = ["uv", "pip", "install"]
    backend = group.get("torch_backend", "")
    if backend:
        args.append(f"--torch-backend={backend}")
    return [*args, *packages]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--matrix", type=Path, default=DEFAULT_MATRIX)
    parser.add_argument("--group-id", required=True)
    parser.add_argument("--build-identifier", required=True)
    args = parser.parse_args()

    group = load_group(args.matrix, args.group_id)
    subprocess.run(install_args(group, args.build_identifier), check=True)
    subprocess.run([
        "uv",
        "pip",
        "install",
        "-r",
        "pyproject.toml",
        "--group",
        "optional",
        "--group",
        "build",
    ], check=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
