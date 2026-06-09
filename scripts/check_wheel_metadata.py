#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from email.parser import Parser
from pathlib import Path
from zipfile import ZipFile


DEFAULT_MATRIX = Path("ci/build-matrix.json")
WHEEL_RE = re.compile(
    r"^(?P<name>.+)-(?P<version>[^-]+)-(?P<py>[^-]+)-(?P<abi>[^-]+)-(?P<plat>[^-]+)\.whl$"
)


def load_group(path: Path, group_id: str) -> dict:
    config = json.loads(path.read_text())
    for group in config.get("build_groups", []):
        if group.get("id") == group_id:
            return group
    raise SystemExit(f"Unknown build group: {group_id}")


def normalize_name(name: str) -> str:
    return name.replace("-", "_").lower()


def parse_wheel_name(path: Path) -> dict[str, str]:
    match = WHEEL_RE.match(path.name)
    if not match:
        raise SystemExit(f"Invalid wheel filename: {path.name}")
    return match.groupdict()


def build_identifier(parts: dict[str, str]) -> str:
    platform = parts["plat"]
    if platform.startswith("manylinux"):
        return f"{parts['py']}-manylinux_x86_64"
    return f"{parts['py']}-{platform}"


def read_metadata(path: Path) -> dict[str, str]:
    with ZipFile(path) as wheel:
        metadata_names = [
            name for name in wheel.namelist()
            if name.endswith(".dist-info/METADATA")
        ]
        if len(metadata_names) != 1:
            raise SystemExit(
                f"{path.name}: expected one METADATA file, found {len(metadata_names)}"
            )
        message = Parser().parsestr(
            wheel.read(metadata_names[0]).decode("utf-8", errors="replace")
        )
    return {"name": message.get("Name", ""), "version": message.get("Version", "")}


def has_native_ext(path: Path) -> bool:
    with ZipFile(path) as wheel:
        return any(
            name.startswith("mmcv/_ext") and (name.endswith(".so") or name.endswith(".pyd"))
            for name in wheel.namelist()
        )


def run_auditwheel_show(path: Path) -> None:
    result = subprocess.run(
        ["auditwheel", "show", str(path)],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    print(result.stdout)
    if result.returncode != 0:
        raise SystemExit(f"auditwheel show failed for {path.name}")


def validate_wheel(
    path: Path,
    group: dict,
    package_name: str,
    version: str,
    require_ext: bool,
    auditwheel: bool,
) -> dict[str, str]:
    parts = parse_wheel_name(path)
    metadata = read_metadata(path)

    if normalize_name(metadata["name"]) != normalize_name(package_name):
        raise SystemExit(
            f"{path.name}: metadata name {metadata['name']!r} != {package_name!r}"
        )
    if metadata["version"] != version:
        raise SystemExit(
            f"{path.name}: metadata version {metadata['version']!r} != {version!r}"
        )
    if parts["version"] != version:
        raise SystemExit(
            f"{path.name}: filename version {parts['version']!r} != {version!r}"
        )
    if "x86_64" not in parts["plat"]:
        raise SystemExit(f"{path.name}: expected x86_64 platform tag")

    identifier = build_identifier(parts)
    torch_by_build = group["torch_by_build"]
    if identifier not in torch_by_build:
        raise SystemExit(f"{path.name}: {identifier!r} is not configured for {group['id']}")
    if require_ext and not has_native_ext(path):
        raise SystemExit(f"{path.name}: missing mmcv._ext native extension")
    if auditwheel:
        run_auditwheel_show(path)

    return {
        "filename": path.name,
        "group": group["id"],
        "cuda": group["cuda"],
        "torch": torch_by_build[identifier]["torch"],
        "build_identifier": identifier,
        "python_tag": parts["py"],
        "platform_tag": parts["plat"],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--wheel-dir", type=Path, required=True)
    parser.add_argument("--matrix", type=Path, default=DEFAULT_MATRIX)
    parser.add_argument("--group-id", required=True)
    parser.add_argument("--package-name", default="onedl-mmcv")
    parser.add_argument("--version", required=True)
    parser.add_argument("--require-ext", action="store_true")
    parser.add_argument("--auditwheel", action="store_true")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    group = load_group(args.matrix, args.group_id)
    wheels = sorted(args.wheel_dir.glob("*.whl"))
    if not wheels:
        raise SystemExit(f"No wheels found in {args.wheel_dir}")

    records = [
        validate_wheel(
            wheel,
            group=group,
            package_name=args.package_name,
            version=args.version,
            require_ext=args.require_ext,
            auditwheel=args.auditwheel,
        )
        for wheel in wheels
    ]

    expected = set(group["torch_by_build"])
    actual = {record["build_identifier"] for record in records}
    missing = expected - actual
    if missing:
        raise SystemExit(f"Missing wheels for build identifiers: {', '.join(sorted(missing))}")

    payload = {"group": group["id"], "wheels": records}
    if args.output:
        args.output.write_text(json.dumps(payload, indent=2, sort_keys=True))
    else:
        print(json.dumps(payload, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
