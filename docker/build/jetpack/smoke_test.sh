#!/usr/bin/env bash
set -euo pipefail

image="$1"
id="$2"

docker run --rm --entrypoint bash "$image" -euxo pipefail -c '
  test -x /entrypoint.sh
  test -d /mmcv
  test -x /mmcv/.venv/bin/python
  /mmcv/.venv/bin/python --version
  /mmcv/.venv/bin/python -c "import torch; print(torch.__version__)"
  uv --version
'

case "$id" in
  jetpack61-*) ;;
  *) echo "unexpected JetPack builder id: $id" >&2; exit 1 ;;
esac
