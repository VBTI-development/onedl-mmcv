#!/usr/bin/env bash
# cibuildwheel repair-wheel-command wrapper: repair the wheel, then surface
# sccache statistics so cache hit rates are visible in the build log. This is
# the only post-compile hook that runs in the same container as the build.
set -euo pipefail

wheel="$1"
dest="$2"

auditwheel repair "$wheel" -w "$dest" \
  --exclude libc10.so \
  --exclude libc10_cuda.so \
  --exclude libtorch.so \
  --exclude libtorch_cpu.so \
  --exclude libtorch_cuda.so \
  --exclude libtorch_python.so \
  --exclude libshm.so

sccache --show-stats || true
