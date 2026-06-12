#!/usr/bin/env bash
set -euo pipefail

CCACHE_VERSION="${CCACHE_VERSION:-v4.13.6}"
version="${CCACHE_VERSION#v}"
asset="ccache-${version}-linux-x86_64-musl-static"
url="https://github.com/ccache/ccache/releases/download/${CCACHE_VERSION}/${asset}.tar.gz"
shim_dir=/opt/ccache-shims

if [[ ! -x /usr/local/bin/ccache ]]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL "$url" -o "$tmp/ccache.tar.gz"
  tar -xzf "$tmp/ccache.tar.gz" -C "$tmp"
  install -m 0755 "$tmp/${asset}/ccache" /usr/local/bin/ccache
fi

if [[ -n "${GCC_TOOLSET:-}" ]]; then
  real_cxx="/opt/rh/gcc-toolset-${GCC_TOOLSET}/root/usr/bin/c++"
else
  path_without_shims="$(printf '%s' "$PATH" | tr ':' '\n' | grep -vx "$shim_dir" | grep -vx /opt/sccache-shims | paste -sd: -)"
  real_cxx="$(PATH="$path_without_shims" command -v c++ || PATH="$path_without_shims" command -v g++ || true)"
fi

if [[ -z "$real_cxx" || ! -x "$real_cxx" ]]; then
  printf 'no real host C++ compiler found for the ccache shim\n' >&2
  exit 1
fi

mkdir -p "$shim_dir" "${CCACHE_TEMPDIR:-/tmp/ccache}"
cat >"$shim_dir/c++" <<EOF
#!/bin/sh
for arg in "\$@"; do
  if [ "\$arg" = "-c" ]; then
    exec ccache "$real_cxx" "\$@"
  fi
done
exec "$real_cxx" "\$@"
EOF
chmod 0755 "$shim_dir/c++"

ccache --version
ccache --zero-stats || true
ccache --show-config || true
printf 'ccache host C++ shim: %s -> %s\n' "$shim_dir/c++" "$real_cxx"
