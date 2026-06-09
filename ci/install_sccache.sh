#!/usr/bin/env bash
# Install a static sccache binary inside the cibuildwheel manylinux container.
# The musl build is statically linked, so it runs on both glibc 2.17
# (manylinux2014) and glibc 2.34 (manylinux_2_34) images.
set -euo pipefail

SCCACHE_VERSION="${SCCACHE_VERSION:-v0.10.0}"  # >= 0.10.0 required for the GHA cache v2 backend
arch="x86_64-unknown-linux-musl"
asset="sccache-${SCCACHE_VERSION}-${arch}"
url="https://github.com/mozilla/sccache/releases/download/${SCCACHE_VERSION}/${asset}.tar.gz"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "$url" -o "$tmp/sccache.tar.gz"
tar -xzf "$tmp/sccache.tar.gz" -C "$tmp"
install -m 0755 "$tmp/${asset}/sccache" /usr/local/bin/sccache

sccache --version
