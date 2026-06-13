#!/usr/bin/env bash
# Reclaim runner disk between cibuildwheel Python versions.
#
# cibuildwheel builds every Python in one container with --no-isolation, so
# select_torch.py installs torch + the CUDA runtime wheels straight into the
# image's system interpreter (/opt/python/cpXXX). With UV_LINK_MODE=copy each
# install is a full ~7 GB copy, and those trees are never removed, so cp310 +
# cp311 + cp312 pile up and the cp313 build runs out of space (ENOSPC while
# copying libcudnn). cibuildwheel has no post-build hook, so this runs first in
# before-build to drop the previous versions' heavy deps; select_torch.py then
# reinstalls them for the version about to build. Earlier versions no longer
# need them (their wheels are already built and repaired).
set -euo pipefail

for site in /opt/python/cp*/lib/python*/site-packages; do
  [ -d "$site" ] || continue
  rm -rf \
    "$site"/torch "$site"/torch-*.dist-info "$site"/torchgen "$site"/functorch \
    "$site"/torchvision "$site"/torchvision-*.dist-info "$site"/torchvision.libs \
    "$site"/triton "$site"/triton-*.dist-info \
    "$site"/nvidia "$site"/nvidia_*.dist-info \
    2>/dev/null || true
done

df -h / 2>/dev/null || true
