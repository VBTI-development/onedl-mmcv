#!/usr/bin/env bash
set -euo pipefail

image="$1"
id="$2"

expected_pythons="cp310-cp310 cp311-cp311 cp312-cp312"
case "$id" in
  ml234-*) expected_pythons="$expected_pythons cp313-cp313" ;;
esac

docker run --rm \
  -e EXPECTED_PYTHONS="$expected_pythons" \
  "$image" bash -euxo pipefail -c '
  test -d /opt/python
  for py in ${EXPECTED_PYTHONS}; do
    test -x "/opt/python/${py}/bin/python"
    "/opt/python/${py}/bin/python" --version
  done

  auditwheel --version
  test -n "${AUDITWHEEL_PLAT:-}"
  case "${AUDITWHEEL_PLAT}" in
    manylinux*) ;;
    *) echo "unexpected AUDITWHEEL_PLAT=${AUDITWHEEL_PLAT}" >&2; exit 1 ;;
  esac

  uv --version
  ccache --version
  test -x /opt/ccache-shims/c++
  /opt/ccache-shims/c++ --version

  nvcc --version
  printf "%s\n" "__global__ void k(){}" >/tmp/smoke.cu
  nvcc -c /tmp/smoke.cu -o /tmp/smoke.o
  test -s /tmp/smoke.o
'

case "$id" in
  *cu126* | *gcc13*)
    docker run --rm "$image" bash -euxo pipefail -c '
      test -x /opt/rh/gcc-toolset-13/root/usr/bin/c++
      version="$(/opt/rh/gcc-toolset-13/root/usr/bin/c++ -dumpfullversion)"
      case "$version" in
        13*) ;;
        *) echo "expected GCC 13, got ${version}" >&2; exit 1 ;;
      esac
    '
    ;;
esac
