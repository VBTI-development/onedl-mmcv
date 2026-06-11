#!/bin/sh
set -e

# Build without isolation so setup.py can import the venv's torch and compile _ext
uv build --no-build-isolation


# By default, run auditwheel repair unless SKIP_REPAIR_WHEEL=1 is set
if [ "$SKIP_REPAIR_WHEEL" = "1" ]; then
    cp dist/*.whl /out
else
    uvx auditwheel repair dist/*.whl -w dist/wheelhouse \
        -z 9 \
        --exclude libc10.so \
        --exclude libc10_cuda.so \
        --exclude libtorch.so \
        --exclude libtorch_cpu.so \
        --exclude libtorch_cuda.so \
        --exclude libtorch_python.so \
        --exclude libshm.so
    cp dist/wheelhouse/*.whl /out
fi
cp dist/*.tar.gz /out
