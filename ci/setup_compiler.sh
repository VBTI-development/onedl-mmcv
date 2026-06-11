#!/usr/bin/env bash
# Install a CUDA-compatible host compiler when the build matrix requests one.
#
# manylinux_2_34 (AlmaLinux 9) defaults to gcc-toolset-14 (GCC 14), but CUDA
# 12.6's nvcc caps the host compiler at GCC 13 (crt/host_config.h), and torch's
# _check_cuda_version aborts the wheel build before any file is compiled. When a
# target sets gcc_toolset=<N> in ci/build-matrix.json, install that toolset here.
# publish.yml prepends /opt/rh/gcc-toolset-<N>/root/usr/{bin,lib64} to PATH and
# LD_LIBRARY_PATH so the sccache shim, torch's version check, and nvcc's host
# compiler all resolve to the compatible GCC. Targets without gcc_toolset (the
# common case) skip this entirely.
set -euo pipefail

toolset="${GCC_TOOLSET:-}"
[ -n "$toolset" ] || exit 0

prefix="/opt/rh/gcc-toolset-${toolset}/root/usr"
if [ ! -x "${prefix}/bin/g++" ]; then
  dnf install -y "gcc-toolset-${toolset}-gcc" "gcc-toolset-${toolset}-gcc-c++"
  dnf clean all
fi

"${prefix}/bin/g++" --version | head -n 1
