# FROM pytorch/pytorch:${PYTORCH}-cuda${CUDA}-cudnn${CUDNN}-devel
FROM nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04

ARG PYTORCH="2.9.1"
ARG PYTHON_VERSION="3.12"

# To fix GPG key error when running apt-get update
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub \
    && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/7fa2af80.pub

# Install git and system dependencies for opencv-python
RUN apt-get update && apt-get install -y git curl libgl1 libglib2.0-0 ffmpeg libturbojpeg && \
    apt-get install -y wget build-essential git software-properties-common locales && \
    apt-get install -y python${PYTHON_VERSION}-dev && \
    apt-get update && \
    apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# RUN uv venv --python ${PYTHON_VERSION} && uv pip install torch==${PYTORCH} torchvision --index-url https://download.pytorch.org/whl/cu129

# build mmcv from source with develop mode
# ARG HTTPS_PROXY=""
# ENV https_proxy=${HTTPS_PROXY}
# ENV FORCE_CUDA="1"
# ARG CUDA_ARCH=""
# ENV TORCH_CUDA_ARCH_LIST=${CUDA_ARCH}
# RUN git clone https://github.com/vbti-development/onedl-mmcv.git /mmcv
# WORKDIR /mmcv
# RUN git checkout 2.x && git rev-parse --short HEAD
# RUN pip install --no-cache-dir -e .[all] -v &&

# RUN uv pip install pre-commit
