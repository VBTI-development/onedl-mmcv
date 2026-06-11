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

redact_sccache_log() {
  sed -E \
    -e 's/(ACTIONS_RUNTIME_TOKEN|SCCACHE_GHA_RUNTIME_TOKEN)=([^[:space:]]+)/\1=[REDACTED]/g' \
    -e 's/(token=)[^&[:space:]]+/\1[REDACTED]/g' \
    -e 's/(Bearer )[A-Za-z0-9._~+\/=:-]+/\1[REDACTED]/g' \
    "$1"
}

write_compiler_diag() {
  local output="$1"
  local real_cxx=""
  {
    printf 'CXX=%s\n' "${CXX:-}"
    if [[ -n "${CXX:-}" ]]; then
      printf 'CXX resolved=%s\n' "$(readlink -f "$CXX" 2>/dev/null || true)"
      "$CXX" --version 2>&1 | head -n 1 || true
      sha256sum "$CXX" 2>/dev/null || true
      real_cxx="$(awk '$1 == "exec" && $2 == "sccache" {gsub(/"/, "", $3); print $3; exit}' "$CXX" 2>/dev/null || true)"
      if [[ -z "$real_cxx" ]]; then
        real_cxx="$(awk '$1 == "exec" && $2 != "sccache" {gsub(/"/, "", $2); print $2; exit}' "$CXX" 2>/dev/null || true)"
      fi
      if [[ -n "$real_cxx" && "$real_cxx" != '$real_cxx' ]]; then
        printf 'real CXX=%s\n' "$real_cxx"
        printf 'real CXX resolved=%s\n' "$(readlink -f "$real_cxx" 2>/dev/null || true)"
        "$real_cxx" --version 2>&1 | head -n 1 || true
        sha256sum "$real_cxx" 2>/dev/null || true
      fi
    fi
  } >"$output" 2>&1 || true
}

wheel_tag="$(python - "$wheel" <<'PY'
import pathlib
import re
import sys
name = pathlib.Path(sys.argv[1]).name
match = re.search(r'-(cp\d+)-cp\d+-', name)
print(match.group(1) if match else 'unknown')
PY
)"
log_dir="${SCCACHE_DIAGNOSTIC_DIR:-$dest/sccache-logs/${MMCV_BUILD_GROUP:-unknown}}"
mkdir -p "$log_dir"
compiler_diag="$log_dir/compiler-${wheel_tag}.txt"
write_compiler_diag "$compiler_diag"
printf 'compiler diagnostics: %s\n' "$compiler_diag"

if [[ -n "${SCCACHE_ERROR_LOG:-}" && -s "$SCCACHE_ERROR_LOG" ]]; then
  redacted_log="$log_dir/sccache-${wheel_tag}.log"
  redact_sccache_log "$SCCACHE_ERROR_LOG" >"$redacted_log" || true
  printf 'sccache full redacted log: %s\n' "$redacted_log"
  printf 'sccache log (last 200 lines, redacted):\n'
  tail -n 200 "$redacted_log" || true

  if [[ "${SCCACHE_PREPROCESSOR_PROBE:-0}" != 0 && "${CUDA:-}" = cpu ]]; then
    python /project/ci/sccache_probe.py \
      --wheel "$wheel" \
      --log "$SCCACHE_ERROR_LOG" \
      --output "$log_dir/preprocess-${wheel_tag}.json" \
      || true
  fi
else
  printf 'sccache error log: absent or empty\n'
fi
