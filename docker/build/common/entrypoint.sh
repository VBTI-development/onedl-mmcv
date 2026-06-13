#!/usr/bin/env bash
set -euo pipefail

project_dir="${PROJECT_DIR:-$(pwd)}"
out_dir="${OUT_DIR:-/out}"
build_dist="${BUILD_DIST_DIR:-/tmp/mmcv-dist}"
wheelhouse="${WHEELHOUSE_DIR:-/tmp/mmcv-wheelhouse}"

if [[ ! -f "$project_dir/pyproject.toml" ]]; then
    echo "project source not found at $project_dir" >&2
    exit 1
fi

cd "$project_dir"
mkdir -p "$out_dir"
rm -rf "$build_dist" "$wheelhouse"
mkdir -p "$build_dist" "$wheelhouse"

if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    export PATH="$VIRTUAL_ENV/bin:$PATH"
fi
if [[ -n "${VIRTUAL_ENV:-}" && -z "${UV_PROJECT_ENVIRONMENT:-}" ]]; then
    export UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"
fi

uv sync --group build --group optional --no-install-project --inexact
uv build --no-build-isolation --out-dir "$build_dist"

if [[ "${SKIP_REPAIR_WHEEL:-0}" = "1" ]]; then
    cp "$build_dist"/*.whl "$out_dir"/
else
    uvx auditwheel repair "$build_dist"/*.whl -w "$wheelhouse" \
        -z 9 \
        --exclude libc10.so \
        --exclude libc10_cuda.so \
        --exclude libtorch.so \
        --exclude libtorch_cpu.so \
        --exclude libtorch_cuda.so \
        --exclude libtorch_python.so \
        --exclude libshm.so
    cp "$wheelhouse"/*.whl "$out_dir"/
fi
cp "$build_dist"/*.tar.gz "$out_dir"/
