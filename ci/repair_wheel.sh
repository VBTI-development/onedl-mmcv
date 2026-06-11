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

if [[ -n "${SCCACHE_ERROR_LOG:-}" && -s "$SCCACHE_ERROR_LOG" ]]; then
  printf 'sccache log (last 200 lines, redacted):\n'
  tail -n 200 "$SCCACHE_ERROR_LOG" | sed -E \
    -e 's/(ACTIONS_RUNTIME_TOKEN|SCCACHE_GHA_RUNTIME_TOKEN)=([^[:space:]]+)/\1=[REDACTED]/g' \
    -e 's/(token=)[^&[:space:]]+/\1[REDACTED]/g' \
    -e 's/(Bearer )[A-Za-z0-9._~+\/=:-]+/\1[REDACTED]/g' \
    || true
else
  printf 'sccache error log: absent or empty\n'
fi
