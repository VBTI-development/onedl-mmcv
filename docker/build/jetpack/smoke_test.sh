#!/usr/bin/env bash
set -euo pipefail

image="$1"
id="$2"

docker run --rm \
  -v "$(pwd):/workspace:ro" \
  --entrypoint bash \
  "$image" -euxo pipefail -c '
  test -x /entrypoint.sh
  test -x /opt/mmcv-venv/bin/python
  /opt/mmcv-venv/bin/python --version
  /opt/mmcv-venv/bin/python -c "import torch; print(torch.__version__)"
  test -f /workspace/pyproject.toml
  test ! -e /mmcv/pyproject.toml
  uv --version
'

case "$id" in
  jetpack61-*) ;;
  *) echo "unexpected JetPack builder id: $id" >&2; exit 1 ;;
esac
