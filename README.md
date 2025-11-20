<div align="center">
  <picture>
    <!-- User prefers dark mode: -->
  <source srcset="https://raw.githubusercontent.com/vbti-development/onedl-mmcv/main/docs/en/_static/image/onedl-mmcv-banner-dark.png"  media="(prefers-color-scheme: dark)"/>

<img src="https://raw.githubusercontent.com/vbti-development/onedl-mmcv/main/docs/en/_static/image/onedl-mmcv-banner.png" alt="OneDL-MMCV logo" height="200"/>
</picture>

<div>&nbsp;</divheightcenter">
    <a href="https://vbti.nl">
      <b><font size="5">VBTI Website</font></b>
    </a>
    &nbsp;&nbsp;&nbsp;&nbsp;
    <a href="https://onedl.ai">
      <b><font size="5">OneDL platform</font></b>
    </a>
  </div>
  <div>&nbsp;</div>

[![Docs](https://img.shields.io/badge/docs-latest-blue)](https://onedl-mmcv.readthedocs.io/en/latest/)
[![license](https://img.shields.io/github/license/vbti-development/onedl-mmcv.svg)](https://github.com/vbti-development/onedl-mmcv/blob/main/LICENSE)

[![pytorch](https://img.shields.io/badge/pytorch-2.4~2.8-yellow)](#installation)
[![cuda](https://img.shields.io/badge/cuda-11.8~12.9-green)](https://developer.nvidia.com/cuda-downloads)
[![platform](https://img.shields.io/badge/platform-Linux-blue)](https://onedl-mmcv.readthedocs.io/en/latest/get_started/installation.html)
[![PyPI - Python Version](https://img.shields.io/pypi/pyversions/onedl-mmcv)](https://pypi.org/project/onedl-mmcv/)
[![PyPI](https://img.shields.io/pypi/v/onedl-mmcv)](https://pypi.org/project/onedl-mmcv)

[![Build Status](https://github.com/vbti-development/onedl-mmcv/workflows/merge_stage_test/badge.svg)](https://github.com/vbti-development/onedl-mmcv/actions)
[![Docker Image](https://github.com/vbti-development/onedl-mmcv/workflows/docker/badge.svg)](https://github.com/vbti-development/onedl-mmcv/actions)
[![open issues](https://isitmaintained.com/badge/open/VBTI-development/onedl-mmcv.svg)](https://github.com/VBTI-development/onedl-mmcv/issues)
[![issue resolution](https://isitmaintained.com/badge/resolution/VBTI-development/onedl-mmcv.svg)](https://github.com/VBTI-development/onedl-mmcv/issues)

[📘Documentation](https://onedl-mmcv.readthedocs.io/en/latest/) |
[🛠️Installation](https://onedl-mmcv.readthedocs.io/en/latest/get_started/installation.html) |
[🤔Reporting Issues](https://github.com/vbti-development/onedl-mmcv/issues/new/choose)

</div>

## Highlights

The VBTI development team is reviving MMLabs code, making it work with
newer pytorch versions and fixing bugs. We are only a small team, so your help
is appreciated. We will officially drop support for the 1.x branch.

We are publishing a number of pre-built wheels for onedl-mmcv, as well as a [Docker Image](https://hub.docker.com/r/vbti/onedl-mmcv-cu129-torch280).

## Introduction

OneDL-MMCV is a foundational library for computer vision research and it provides the following functionalities:

- [Image/Video processing](https://onedl-mmcv.readthedocs.io/en/latest/understand_mmcv/data_process.html)
- [Image and annotation visualization](https://onedl-mmcv.readthedocs.io/en/latest/understand_mmcv/visualization.html)
- [Image transformation](https://onedl-mmcv.readthedocs.io/en/latest/understand_mmcv/data_transform.html)
- [Various CNN architectures](https://onedl-mmcv.readthedocs.io/en/latest/understand_mmcv/cnn.html)
- [High-quality implementation of common CPU and CUDA ops](https://onedl-mmcv.readthedocs.io/en/latest/understand_mmcv/ops.html)

It supports the following systems:

- Linux
- Windows
- macOS

However, since VBTI took over, we only test it on Linux.

See the [documentation](http://onedl-mmcv.readthedocs.io/en/latest) for more features and usage.

Note: OneDL-MMCV requires Python 3.10+.

## Installation

MMCV contains various CUDA ops, so it takes a longer time to build.
We do publish a number of prebuilt wheels, such that you don't have to build it yourself.
Make sure the python version, CUDA version and Pytorch versions you are using are supported.
We made a [custom PyPI index](https://mmwheels.onedl.ai/) that groups CUDA-Pytorch version.

### Install mmcv

Before installing mmcv, make sure that PyTorch has been successfully installed following the [PyTorch official installation guide](https://github.com/pytorch/pytorch#installation).
(Recommended version is 2.8.0)

The command to install mmcv:

```bash
pip install -U onedl-mim
mim install onedl-mmcv
```

If you need to specify the version of mmcv, you can use the following command:

```bash
mim install onedl-mmcv==2.3.2
```

If you find that the above installation command does not use a pre-built package ending with `.whl` but a source package ending with `.tar.gz`, you may not have a pre-build package corresponding to the PyTorch, CUDA, python or onedl-mmcv version, in which case you can [build mmcv from source](https://onedl-mmcv.readthedocs.io/en/latest/get_started/build.html).

<details>
<summary>Installation log using pre-built packages</summary>

Looking in links: https://mmwheels.onedl.ai/simple/cu126-torch2.4.1/index.html<br />
Collecting mmcv<br />
<b>Downloadinghttps://mmwheels.onedl.ai/simple/cu126-torch2.4.1/mmcv-2.0.0-cp38-cp38-manylinux1_x86_64.whl</b>

</details>

<details>
<summary>Installation log using source packages</summary>

Looking in links: https://mmwheels.onedl.ai/simple/cu126-torch2.4.1/index.html<br />
Collecting mmcv==2.0.0<br />
<b>Downloading mmcv-2.0.0.tar.gz</b>

</details>

For more installation methods, please refer to the [Installation documentation](https://onedl-mmcv.readthedocs.io/en/latest/get_started/installation.html).

## FAQ

If you face some installation issues, CUDA related issues or RuntimeErrors,
you may first refer to this [Frequently Asked Questions](https://onedl-mmcv.readthedocs.io/en/latest/faq.html).

If you face installation problems or runtime issues, you may first refer to this [Frequently Asked Questions](https://onedl-mmcv.readthedocs.io/en/latest/faq.html) to see if there is a solution. If the problem is still not solved, feel free to open an [issue](https://github.com/vbti-development/onedl-mmcv/issues).

## Citation

If you find this project useful in your research, please consider cite:

```latex
@misc{mmcv,
    title={OneDL-MMCV} Computer Vision Foundation},
    author={OneDL-MMCV Contributors},
    howpublished = {\url{https://github.com/vbti-development/onedl-mmcv}},
    year={2025}
}
```

## Contributing

We appreciate all contributions to improve OneDL-MMCV. Please refer to [CONTRIBUTING.md](CONTRIBUTING.md) for the contributing guideline.

## License

OneDL-MMCV is released under the Apache 2.0 license, while some specific operations in this library are with other licenses. Please refer to [LICENSES.md](LICENSES.md) for the careful check, if you are using our code for commercial matters.

## Projects in VBTI-development

- [OneDL-MMEngine](https://github.com/vbti-development/onedl-mmengine): Foundational library for training deep learning models.
- [OneDL-MMCV](https://github.com/vbti-development/onedl-mmcv): Foundational library for computer vision.
- [OneDL-MMPreTrain](https://github.com/vbti-development/onedl-mmpretrain): Pre-training toolbox and benchmark.
- [OneDL-MMDetection](https://github.com/vbti-development/onedl-mmdetection): Detection toolbox and benchmark.
- [OneDL-MMRotate](https://github.com/vbti-development/onedl-mmrotate): Rotated object detection toolbox and benchmark.
- [OneDL-MMSegmentation](https://github.com/vbti-development/onedl-mmsegmentation): Semantic segmentation toolbox and benchmark.
- [OneDL-MMDeploy](https://github.com/vbti-development/onedl-mmdeploy): Model deployment framework.
- [OneDL-MIM](https://github.com/vbti-development/onedl-mim): MIM installs VBTI packages.
