#!/usr/bin/env bash
set -euo pipefail

image="$1"
id="$2"

docker run --rm "$image" bash -euxo pipefail -c '
  test -x /opt/python/cp310-cp310/bin/python
  test -x /opt/python/cp311-cp311/bin/python
  test -x /opt/python/cp312-cp312/bin/python
  test -x /opt/python/cp313-cp313/bin/python
  test "${AUDITWHEEL_PLAT}" = "manylinux_2_28_x86_64"
  auditwheel --version
  uv --version
  sccache --version
  test -x /opt/sccache-shims/c++
  /opt/sccache-shims/c++ --version
'

case "$id" in
  ml228-cpu) ;;
  *) echo "unexpected manylinux CPU builder id: $id" >&2; exit 1 ;;
esac
