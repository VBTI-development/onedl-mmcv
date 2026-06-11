#!/usr/bin/env bash
# Install a static sccache binary inside the cibuildwheel manylinux container.
# The musl build is statically linked, so it runs on both glibc 2.17
# (manylinux2014) and glibc 2.34 (manylinux_2_34) images.
set -euo pipefail

if [[ "${SCCACHE_GHA_ENABLED:-}" = true ]]; then
  missing=()
  for name in ACTIONS_RESULTS_URL ACTIONS_RUNTIME_TOKEN ACTIONS_CACHE_SERVICE_V2; do
    if [[ -z "${!name:-}" ]]; then
      missing+=("$name")
    fi
  done
  if (( ${#missing[@]} )); then
    printf '::error::Missing required sccache GHA environment variable(s) in the cibuildwheel container: %s\n' "${missing[*]}"
    exit 1
  fi

  printf 'sccache GHA environment: SCCACHE_GHA_ENABLED=%s, ACTIONS_CACHE_SERVICE_V2=%s, ACTIONS_RESULTS_URL=present(%d bytes), ACTIONS_RUNTIME_TOKEN=present(%d bytes)\n' \
    "$SCCACHE_GHA_ENABLED" "$ACTIONS_CACHE_SERVICE_V2" "${#ACTIONS_RESULTS_URL}" "${#ACTIONS_RUNTIME_TOKEN}"
  if [[ -n "${ACTIONS_CACHE_URL:-}" ]]; then
    printf 'sccache GHA environment: ACTIONS_CACHE_URL=present(%d bytes, legacy fallback)\n' "${#ACTIONS_CACHE_URL}"
  else
    printf 'sccache GHA environment: ACTIONS_CACHE_URL=absent (expected for GHA v2)\n'
  fi
else
  printf 'sccache storage: local disk backend (SCCACHE_DIR=%s)\n' "${SCCACHE_DIR:-default}"
fi

# Project-owned builder images preinstall sccache and the compiler shim. Reuse
# them instead of rewriting the shim and risking wrapper recursion.
shim_dir=/opt/sccache-shims
if [[ -x /usr/local/bin/sccache && -x "$shim_dir/c++" ]]; then
  sccache --version
  printf 'using preinstalled sccache host C++ shim: %s\n' "$shim_dir/c++"
  exit 0
fi

SCCACHE_VERSION="${SCCACHE_VERSION:-v0.15.0}"  # >= 0.11.0 fixes GHA cache (ghac) writes; pin matches sccache-action
arch="x86_64-unknown-linux-musl"
asset="sccache-${SCCACHE_VERSION}-${arch}"
url="https://github.com/mozilla/sccache/releases/download/${SCCACHE_VERSION}/${asset}.tar.gz"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "$url" -o "$tmp/sccache.tar.gz"
tar -xzf "$tmp/sccache.tar.gz" -C "$tmp"
install -m 0755 "$tmp/${asset}/sccache" /usr/local/bin/sccache

sccache --version

# Wrap the host C++ compiler so the ~200 .cpp objects are cached too (nvcc is
# wrapped separately via PYTORCH_NVCC). torch's ninja build reads $CXX for the
# host compile rule; we point it at an absolute single-token shim to avoid the
# setuptools>=60 space-prefix link regression that CXX="sccache c++" triggers.
path_without_shim="$(printf '%s' "$PATH" | tr ':' '\n' | grep -vx "$shim_dir" | paste -sd: -)"
real_cxx="$(PATH="$path_without_shim" command -v c++ || PATH="$path_without_shim" command -v g++ || true)"
if [[ -z "$real_cxx" || "$real_cxx" = "$shim_dir/c++" ]]; then
  printf '::error::no real host C++ compiler (c++/g++) found for the sccache shim\n'
  exit 1
fi
mkdir -p "$shim_dir"
cat >"$shim_dir/c++" <<EOF
#!/bin/sh
# Route only real compiles (-c) through sccache; pass links and everything else
# straight to the compiler so sccache never handles a non-cacheable command.
for arg in "\$@"; do
  if [ "\$arg" = "-c" ]; then
    exec sccache "$real_cxx" "\$@"
  fi
done
exec "$real_cxx" "\$@"
EOF
chmod 0755 "$shim_dir/c++"
printf 'sccache host C++ shim: %s -> sccache %s\n' "$shim_dir/c++" "$real_cxx"
