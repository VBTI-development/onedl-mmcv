# Docker images

This directory contains runtime images and wheel-builder images.

```text
docker/
|-- dev/                 # Development/runtime image built from source
|   `-- Dockerfile
|-- release/             # Runtime image that installs a released onedl-mmcv wheel
|   `-- Dockerfile
`-- build/               # Images used to build release wheels
    |-- common/          # Shared wheel-builder entrypoint
    |-- jetpack/         # Jetson/JetPack aarch64 wheel builders
    |-- manylinux-cpu/   # x86_64 PyPA manylinux CPU builder images
    |-- manylinux-cuda/  # x86_64 PyPA manylinux + CUDA builder images
    `-- legacy/          # Older single-image wheel builders kept for reference
```

## Runtime images

Build a release image that installs the pre-built package:

```bash
docker build -t mmcv -f docker/release/Dockerfile .
```

Build a development image:

```bash
docker build -t mmcv-dev -f docker/dev/Dockerfile --build-arg CUDA_ARCH=7.5 .
```

Run an image with GPU access:

```bash
docker run --gpus all --shm-size=8g -it mmcv
```

## Wheel builder images

Wheel builders live under `docker/build/` and are driven by CI:

- `docker/build/jetpack/` defines Jetson/JetPack aarch64 wheel builder images.
- `docker/build/manylinux-cpu/` defines x86_64 PyPA manylinux CPU builder images.
- `docker/build/manylinux-cuda/` defines x86_64 PyPA manylinux + CUDA builder images.
- `.github/workflows/build-wheel-builder-images.yml` publishes builder images from these directories to GHCR.
- `docker/build/legacy/` preserves the older ad-hoc wheel builder Dockerfiles.
