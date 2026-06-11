# Legacy wheel builder images

These Dockerfiles are kept for manual/reference wheel builds. The release workflow no longer consumes them directly.

## GPU builder

```bash
docker build \
  -f docker/build/legacy/Dockerfile \
  -t mmcv-builder:cu118-torch251 \
  --build-arg CUDA=11.8.0 \
  --build-arg PYTORCH=2.5.1 \
  .
```

Then build a wheel:

```bash
docker run --rm \
  -v "$PWD/dist:/out" \
  -e TORCH_CUDA_ARCH_LIST="7.5 8.6 8.9" \
  mmcv-builder:cu118-torch251
```

## CPU builder

```bash
docker build \
  -f docker/build/legacy/Dockerfile.cpu \
  -t mmcv-builder:cpu-torch251 \
  --build-arg PYTORCH=2.5.1 \
  .
```
