ARG CUDA="12.9.1"
ARG CUDNN=""

FROM nvidia/cuda:${CUDA}-cudnn-runtime-ubuntu22.04
ARG CUDA

# To fix GPG key error when running apt-get update
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub \
    && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/7fa2af80.pub

# Install git and system dependencies for opencv-python
RUN apt-get update \
    && apt-get install -y libgl1 libglib2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:0.8.14 /uv /uvx /bin/

WORKDIR /workspace
ARG PYTHON_VERSION="3.10"
ARG PYTORCH="2.8.0"
ENV UV_LINK_MODE=copy
RUN uv venv --python ${PYTHON_VERSION}
ENV PATH="$PATH:/workspace/.venv/bin"

RUN --mount=type=cache,target=/root/.cache/uv \
    CUDA_SHORT=${CUDA%.*} CU_BE=$(echo $CUDA_SHORT | tr -d .) && uv pip install --torch-backend=cu${CU_BE} torch==${PYTORCH} torchvision

ARG MMCV_VERSION=""
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install onedl-mim && \
    if [ "${MMCV_VERSION}" = "" ]; then mim install onedl-mmcv --only-binary=onedl-mmcv; else mim install onedl-mmcv==${MMCV_VERSION} --only-binary=onedl-mmcv; fi

# Verify the installation
RUN python -c 'import mmcv;print(mmcv.__version__)'
