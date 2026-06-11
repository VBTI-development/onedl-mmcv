#!/usr/bin/env bash
set -euo pipefail

SCCACHE_VERSION="${SCCACHE_VERSION:-v0.15.0}"
asset="sccache-${SCCACHE_VERSION}-x86_64-unknown-linux-musl"
url="https://github.com/mozilla/sccache/releases/download/${SCCACHE_VERSION}/${asset}.tar.gz"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "$url" -o "$tmp/sccache.tar.gz"
tar -xzf "$tmp/sccache.tar.gz" -C "$tmp"
install -m 0755 "$tmp/${asset}/sccache" /usr/local/bin/sccache

if [[ -n "${GCC_TOOLSET:-}" ]]; then
  real_cxx="/opt/rh/gcc-toolset-${GCC_TOOLSET}/root/usr/bin/c++"
else
  real_cxx="$(command -v c++ || command -v g++ || true)"
fi

if [[ -z "$real_cxx" || ! -x "$real_cxx" ]]; then
  printf 'no host C++ compiler found for sccache shim\n' >&2
  exit 1
fi

mkdir -p /opt/sccache-shims
cat >/opt/sccache-shims/c++ <<EOF
#!/bin/sh
for arg in "\$@"; do
  if [ "\$arg" = "-c" ]; then
    exec sccache "$real_cxx" "\$@"
  fi
done
exec "$real_cxx" "\$@"
EOF
chmod 0755 /opt/sccache-shims/c++

sccache --version
/opt/sccache-shims/c++ --version
