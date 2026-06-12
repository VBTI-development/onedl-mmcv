#!/usr/bin/env python3
from __future__ import annotations
import argparse
import ast
import gzip
import hashlib
import json
import os
import re
import shlex
import subprocess
from pathlib import Path

DEFAULT_TARGETS = ('sparse_pool_ops.cpp', 'spconv_ops.cpp', 'voxelization.cpp')
PARSE_ARGS_RE = re.compile(r'parse_arguments: Ok: (\[.*\])')
WHEEL_PY_RE = re.compile(r'-(cp\d+)-cp\d+-')
SOURCE_SUFFIXES = ('.c', '.cc', '.cpp', '.cxx', '.cu')


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def wheel_python_tag(wheel: Path) -> str:
    match = WHEEL_PY_RE.search(wheel.name)
    if not match:
        raise SystemExit(f'Cannot parse Python tag from wheel: {wheel.name}')
    return match.group(1)


def source_arg(args: list[str]) -> str:
    for arg in args:
        if arg.startswith('/project/') and arg.endswith(SOURCE_SUFFIXES):
            return arg
    return next((arg for arg in args if arg.endswith(SOURCE_SUFFIXES)), '')


def output_arg(args: list[str]) -> str:
    for index, arg in enumerate(args[:-1]):
        if arg == '-o':
            return args[index + 1]
    return ''


def iter_compile_args(log: Path, python_tag: str, targets: set[str]):
    cpython = f'cpython-{python_tag[2:]}'
    for line in log.read_text(encoding='utf-8', errors='replace').splitlines():
        match = PARSE_ARGS_RE.search(line)
        if not match:
            continue
        try:
            args = ast.literal_eval(match.group(1))
        except (SyntaxError, ValueError):
            continue
        if not isinstance(args, list):
            continue
        source = source_arg(args)
        output = output_arg(args)
        if source and output and cpython in output and Path(source).name in targets:
            yield source, output, args


def preprocessor_args(args: list[str]) -> list[str]:
    result = ['-E']
    skip_next = False
    skip_with_value = {'-MF', '-MT', '-MQ', '-o'}
    drop = {'-MMD', '-MD', '-MP', '-c'}
    for arg in args:
        if skip_next:
            skip_next = False
            continue
        if arg in skip_with_value:
            skip_next = True
            continue
        if arg not in drop:
            result.append(arg)
    return result


def split_command(value: str, default: str) -> list[str]:
    return shlex.split(value or default)


def uncached_command(command: list[str]) -> list[str]:
    if command and Path(command[0]).name == 'sccache':
        return command[1:]
    return command


def compiler_command(source: str) -> list[str]:
    if source.endswith('.cu'):
        command = split_command(
            os.getenv('SCCACHE_PROBE_CUDA_COMPILER', '')
            or os.getenv('PYTORCH_NVCC', ''),
            '/usr/local/cuda/bin/nvcc')
    else:
        command = split_command(os.getenv('SCCACHE_PROBE_CXX', '')
                                or os.getenv('CXX', ''), 'c++')
    return uncached_command(command)


def probe(
    python_tag: str,
    source: str,
    output: str,
    args: list[str],
    preprocessed_dir: Path,
) -> dict[str, object]:
    compiler = compiler_command(source)
    pp_args = preprocessor_args(args)
    result = subprocess.run(
        [*compiler, *pp_args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    record: dict[str, object] = {
        'source': source,
        'object': output,
        'compiler': compiler,
        'args': args,
        'preprocessor_args': pp_args,
        'args_sha256': sha256('\0'.join(args).encode()),
        'preprocessor_args_sha256': sha256('\0'.join(pp_args).encode()),
        'returncode': result.returncode,
        'stderr_tail': result.stderr.decode('utf-8', errors='replace')[-4000:],
    }
    if result.returncode == 0:
        filename = f'{python_tag}-{Path(source).stem}.ii.gz'
        preprocessed_dir.mkdir(parents=True, exist_ok=True)
        with gzip.open(preprocessed_dir / filename, 'wb') as handle:
            handle.write(result.stdout)
        record['preprocessed_sha256'] = sha256(result.stdout)
        record['preprocessed_size'] = len(result.stdout)
        record['preprocessed_file'] = f'preprocessed/{filename}'
    return record


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--wheel', type=Path, required=True)
    parser.add_argument('--log', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--targets', default=os.getenv('SCCACHE_PROBE_TARGETS', ''))
    args = parser.parse_args()

    targets = {
        item.strip() for item in args.targets.split(',') if item.strip()
    } or set(DEFAULT_TARGETS)
    python_tag = wheel_python_tag(args.wheel)

    records = []
    seen = set()
    preprocessed_dir = args.output.parent / 'preprocessed'
    for source, output, compile_args in iter_compile_args(
        args.log, python_tag, targets
    ):
        name = Path(source).name
        if name in seen:
            continue
        seen.add(name)
        records.append(
            probe(
                python_tag,
                source,
                output,
                compile_args,
                preprocessed_dir,
            )
        )

    payload = {
        'wheel': args.wheel.name,
        'python_tag': python_tag,
        'group': os.getenv('MMCV_BUILD_GROUP', ''),
        'cuda': os.getenv('CUDA', ''),
        'cxx': os.getenv('CXX', ''),
        'pytorch_nvcc': os.getenv('PYTORCH_NVCC', ''),
        'targets': sorted(targets),
        'records': records,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, sort_keys=True))

    print(f'sccache preprocessor probe: wrote {args.output}')
    for record in records:
        digest = record.get('preprocessed_sha256', 'failed')
        size = record.get('preprocessed_size', 0)
        print(f"  {Path(str(record['source'])).name}: {digest} ({size} bytes)")
    if not records:
        print('  no matching compile arguments found')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
