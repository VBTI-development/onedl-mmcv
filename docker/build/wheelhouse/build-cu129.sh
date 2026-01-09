#!/bin/bash

set -e

CUDNN=""
TORCH_CUDA_ARCH_LIST="7.5 8.6 8.9 12.0"

docker build -f Dockerfile -t mmcv-builder:cu129-torch280 . --build-arg CUDA=12.9.1 --build-arg PYTORCH='2.8.0' --build-arg CUDNN=$CUDNN

docker run --rm -e TORCH_CUDA_ARCH_LIST="$TORCH_CUDA_ARCH_LIST" -v wheelhouse/mmcv/dist:/out mmcv-builder:cu129-torch280
