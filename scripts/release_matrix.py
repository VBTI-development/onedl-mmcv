#!/usr/bin/env python3
from __future__ import annotations
import argparse
import json
import re
import sys
from pathlib import Path

DEFAULT_MATRIX = Path('ci/build-matrix.json')
GROUP_ID_RE = re.compile(r'^(?P<prefix>.+)-torch(?P<compact>\d+)$')


def load_matrix(path: Path) -> dict:
    return json.loads(Path(path).read_text())


def compact_torch(version: str) -> str:
    parts = version.split('.')
    if len(parts) < 2:
        raise SystemExit(f"Invalid torch version: {version}")
    patch = parts[2] if len(parts) > 2 else '0'
    return f"{parts[0]}{parts[1]}{patch}"


def _targets(matrix: dict) -> dict:
    return {
        **matrix.get('special_targets', {}),
        **matrix.get('cuda_targets', {})
    }


def _torch_by_build(node: dict, torch: str) -> dict:
    platform = node['platform']
    return {
        f"cp{py.replace('.', '')}-{platform}": {
            'torch': torch,
            'torchvision': ''
        }
        for py in node['torch'][torch]['python']
    }


def resolve_group(matrix: dict, group_id: str) -> dict:
    targets = _targets(matrix)
    node = targets.get(group_id)
    if node is not None:
        versions = list(node['torch'])
        if len(versions) != 1:
            raise SystemExit(
                f"Ambiguous build group {group_id!r}; use '{group_id}-torch<compact>'"  # noqa: E501
            )
        torch = versions[0]
    else:
        match = GROUP_ID_RE.match(group_id)
        if match is None:
            raise SystemExit(f"Unknown build group: {group_id}")
        node = targets.get(match.group('prefix'))
        if node is None:
            raise SystemExit(f"Unknown build group: {group_id}")
        matches = [
            v for v in node['torch']
            if compact_torch(v) == match.group('compact')
        ]
        if not matches:
            raise SystemExit(f"Unknown build group: {group_id}")
        if len(matches) > 1:
            raise SystemExit(f"Ambiguous build group: {group_id}")
        torch = matches[0]
    return {
        'id': group_id,
        'cuda': node['cuda'],
        'torch_backend': node.get('torch_backend', ''),
        'publish_prefix_template': node['publish_prefix_template'],
        'torch_by_build': _torch_by_build(node, torch),
    }


def iter_build_units(matrix: dict):
    sections = (matrix.get('special_targets',
                           {}), matrix.get('cuda_targets', {}))
    for targets in sections:
        for prefix, node in targets.items():
            for torch in node['torch']:
                yield prefix, torch, node


def validate(matrix: dict) -> None:
    compat = matrix.get('pytorch_compatibility', {})
    if not compat:
        raise SystemExit('pytorch_compatibility section is required')
    overlap = set(matrix.get('special_targets', {})) & set(
        matrix.get('cuda_targets', {}))
    if overlap:
        raise SystemExit(
            f"target id used in both sections: {', '.join(sorted(overlap))}")
    for prefix, node in matrix.get('cuda_targets', {}).items():
        if not node.get('manylinux_image'):
            raise SystemExit(
                f"cuda target {prefix!r} is missing manylinux_image")
    for prefix, node in _targets(matrix).items():
        compacts = [compact_torch(torch) for torch in node['torch']]
        if len(compacts) != len(set(compacts)):
            raise SystemExit(
                f"{prefix}: torch versions collide on a compact id")
    for prefix, torch, node in iter_build_units(matrix):
        rule = compat.get(torch)
        if rule is None:
            raise SystemExit(
                f"{prefix}: torch {torch} is absent from pytorch_compatibility"
            )
        cuda = node['cuda']
        if cuda != 'cpu' and cuda not in rule['cuda_stable']:
            raise SystemExit(
                f"{prefix}: torch {torch} + CUDA {cuda} is not an official stable combo"  # noqa: E501
            )
        for py in node['torch'][torch]['python']:
            if py not in rule['python']:
                raise SystemExit(
                    f"{prefix}: torch {torch} does not support Python {py}")
        compact = compact_torch(torch)
        expected_prefix = f"{prefix}-torch{compact}/onedl-mmcv/"
        actual_prefix = node['publish_prefix_template'].format(
            torch_compact=compact)
        if actual_prefix != expected_prefix:
            raise SystemExit(
                f"{prefix}: publish prefix {actual_prefix!r} != expected {expected_prefix!r}"  # noqa: E501
            )


def gen_linux_matrix(matrix: dict) -> dict:
    include = []
    for prefix, torch, node in iter_build_units(matrix):
        platform = node['platform']
        if not platform.endswith('x86_64'):
            continue
        cuda = node['cuda']
        cibw_build = ' '.join(f"cp{py.replace('.', '')}-{platform}"
                              for py in node['torch'][torch]['python'])
        name = (f"Linux CPU wheels (torch {torch})" if cuda == 'cpu' else
                f"Linux CUDA {cuda} wheels (torch {torch})")
        gcc_toolset = node.get('gcc_toolset', '')
        cc_bin = (f"/opt/rh/gcc-toolset-{gcc_toolset}/root/usr/bin:"
                  if gcc_toolset else '')
        cc_lib = (f"/opt/rh/gcc-toolset-{gcc_toolset}/root/usr/lib64:"
                  if gcc_toolset else '')
        include.append({
            'id':
            f"{prefix}-torch{compact_torch(torch)}",
            'name':
            name,
            'runner':
            'ubuntu-24.04',
            'force_cuda':
            '0' if cuda == 'cpu' else '1',
            'cuda':
            cuda,
            'manylinux_image':
            node['manylinux_image'],
            'cibw_build':
            cibw_build,
            'torch_cuda_arch_list':
            node.get('torch_cuda_arch_list', ''),
            'gcc_toolset':
            gcc_toolset,
            'cc_path_prefix':
            cc_bin,
            'cc_ld_prefix':
            cc_lib,
        })
    return {'include': include}


def main() -> int:
    parser = argparse.ArgumentParser(
        description='Release build matrix source of truth')
    parser.add_argument('--matrix', type=Path, default=DEFAULT_MATRIX)
    commands = parser.add_subparsers(dest='command', required=True)
    commands.add_parser(
        'validate',
        help='check every (cuda, torch, python) against pytorch_compatibility')
    gen = commands.add_parser(
        'gen-matrix', help='emit the cibuildwheel matrix as compact JSON')
    gen.add_argument('--kind', choices=['linux'], default='linux')
    args = parser.parse_args()

    matrix = load_matrix(args.matrix)
    if args.command == 'validate':
        validate(matrix)
        print(
            f"ok: {sum(1 for _ in iter_build_units(matrix))} build groups valid"  # noqa: E501
        )
    else:
        validate(matrix)
        print(json.dumps(gen_linux_matrix(matrix), separators=(',', ':')))
    return 0


if __name__ == '__main__':
    sys.exit(main())
