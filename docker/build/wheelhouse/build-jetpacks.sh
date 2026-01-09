#!/bin/bash

set -e

docker build -f Dockerfile.jetpack60 -t mmcv-builder:jp60-torch280 .
docker run --rm -e MAX_JOBS=8 -v "$(pwd)/wheelhouse/dist/jp60":/out mmcv-builder:jp60-torch280

docker build -f Dockerfile.jetpack61 -t mmcv-builder:jp61-torch280 .
docker run --rm -e MAX_JOBS=8 -v "$(pwd)/wheelhouse/dist/jp61":/out mmcv-builder:jp61-torch280
