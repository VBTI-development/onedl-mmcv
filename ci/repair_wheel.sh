#!/usr/bin/env bash
# cibuildwheel repair-wheel-command wrapper: repair the wheel, then surface
# ccache statistics so cache hit rates are visible in the build log.
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

ccache --show-stats || ccache -s || true

redact_cache_log() {
  sed -E \
    -e 's/(ACTIONS_RUNTIME_TOKEN)=([^[:space:]]+)/\1=[REDACTED]/g' \
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
      real_cxx="$(awk '$1 == "exec" && $2 == "ccache" {gsub(/"/, "", $3); print $3; exit}' "$CXX" 2>/dev/null || true)"
      if [[ -z "$real_cxx" ]]; then
        real_cxx="$(awk '$1 == "exec" && $2 != "ccache" {gsub(/"/, "", $2); print $2; exit}' "$CXX" 2>/dev/null || true)"
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
log_dir="${CCACHE_DIAGNOSTIC_DIR:-/output/ccache-logs/${MMCV_BUILD_GROUP:-unknown}}"
mkdir -p "$log_dir"
compiler_diag="$log_dir/compiler-${wheel_tag}.txt"
write_compiler_diag "$compiler_diag"
printf 'compiler diagnostics: %s\n' "$compiler_diag"

if [[ -n "${CCACHE_LOGFILE:-}" && -s "$CCACHE_LOGFILE" ]]; then
  redacted_log="$log_dir/ccache-${wheel_tag}.log"
  redact_cache_log "$CCACHE_LOGFILE" >"$redacted_log" || true
  printf 'ccache full redacted log: %s\n' "$redacted_log"
  printf 'ccache log (last 200 lines, redacted):\n'
  tail -n 200 "$redacted_log" || true
else
  printf 'ccache log: absent or empty\n'
fi
