#!/usr/bin/env bash
# Install a static sccache binary inside the cibuildwheel manylinux container.
# The musl build is statically linked, so it runs on both glibc 2.17
# (manylinux2014) and glibc 2.34 (manylinux_2_34) images.
set -euo pipefail

missing=()
for name in SCCACHE_GHA_ENABLED ACTIONS_RESULTS_URL ACTIONS_RUNTIME_TOKEN ACTIONS_CACHE_SERVICE_V2; do
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
