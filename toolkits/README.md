# AICA Toolkit images

AICA offers a set of scripts to generate toolkit images that may facilitate your development process and/or allow for
better version control between applications that carry similar dependencies that need to be properly handled.

While we offer various preconfigured images through our registry, we compiled these instructions for users that may need
to generate customized libraries and/or change package versions to suite their needs.

More specifically, we offer images for:

- Run- and build-time CUDA tools
- Common Machine Learning (ML) libraries with (NVIDIA) GPU or CPU-only support

We also offer specialized images for NVIDIA's Jetson machines, which often require customized builds for NVIDIA
Jetson's kernel.

## Current AICA registry images

### CUDA toolkit

<!-- | Image name  | CUDA Version | TensorRT Version | Python Version | Description |
|-------------|-----|---|---|--| -->

**No images available yet.**

### ML toolkit

<!-- | Image name  | Target (CPU/GPU) | Needs CUDA | Python Version | Description |
|-------------|-----|---|---|--| -->

**No images available yet.**

### On the use of GPUs

For GPU-dependent images, we currently use NVIDIA's registries to collect the necessary libraries and form the final
toolkit image that can be used with AICA Core and/or custom AICA Components. As such, we also label our versions with
respect to the TensorRT images that we use as our dependency base. If you are creating a custom image for the CUDA or ML
toolkit, refer to the
[TensorRT Release Notes](https://docs.nvidia.com/deeplearning/frameworks/container-release-notes/index.html) for image
tags you can use to pull specific combinations of CUDA, TensorRT, and Python. A simple example of how you can achieve
this can be found [here](#building-a-custom-image).

> **NOTE**
>
> As previously discussed, the Jetson requires special handling for install dependencies due to its custom kernel that
> facilitates interfacing with the GPU. Therefore, to ensure compatibility it is recommended that you use NVIDIA's
> specialized Linux for Tegra (L4T) images, which you can browse
> [here](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/l4t-tensorrt). AICA's Jetson images are also based on L4T
> images.
> 
> You may also need to install custom versions of PyTorch that are built for Tegra (or compile wheels from source). You
> may refer to the this [NVIDIA](https://forums.developer.nvidia.com/t/pytorch-for-jetson/72048) forum post.
>
> That also means that l4t images are can not be used in a drop-in fashion with other multiarch images, as the may
> contain different library version and/or dependencies.

## Using registry images

To use registry images at runtime you may simply add the following line(s) in your `aica-application.toml`:

```toml
#syntax=ghcr.io/aica-technology/app-builder:v2

[core]
image = "v4.4.2"

[packages]
<Other packages you wish to include>
"@aica/foss/toolkits/cuda" = "v1.0.0-cuda24.12-rc0001"
"@aica/foss/toolkits/ml" = "v1.0.0-gpu24.12-rc0001"
```

If your custom component is depending on some of the included packages (e.g., CUDA libraries, torch, ...), note that you
can also include these libraries as build-time dependencies instead of manually adding each and every dependency you
need. This is the suggested dependency handling methodology, as it allows for more precisely version controlling your
components. Adding the toolkit images as build dependencies is also as simple as:

```toml
#syntax=ghcr.io/aica-technology/package-builder:v1.4.0

[metadata]
version = "0.0.1"

[build]
type = "ros"
image = "v2.0.5-jazzy"

[build.dependencies]
"@aica/foss/control-libraries" = "v9.2.0"
"@aica/foss/modulo" = "v5.2.0"

# along with the above core libraries, you can also include the toolkit
# images for easy access to CUDA and ML libraries
"@aica/foss/toolkits/cuda" = "v1.0.0-cuda24.12-rc0001"
"@aica/foss/toolkits/ml" = "v1.0.0-gpu24.12-rc0001"

[build.packages.my_custom_component]
source = "./source/my_custom_component"

[build.packages.my_custom_component.dependencies.apt]
<Add apt dependencies not included in the 2 toolkit images>
```

## Building a custom image

### Example 1

In the simplest case, you may only want to specify a newer TensorRT tag that brings the corresponding CUDA dependencies.
For example, if you specify:

```shell
./build.sh --cuda-toolkit \
  --tensorrt-image-tag 24.12-py3 \
  --target env-vars
```

you will obtain a `ghcr.io/aica-technology/toolkits/cuda:vX.Y.Z-cpu24.04-rc0001` image (refer
[here]((https://docs.nvidia.com/deeplearning/frameworks/container-release-notes/index.html)) for information on CUDA and
TensorRT versions).

Similarly, you can do:

```shell
./build.sh --ml-toolkit \
  --tensorrt-image-tag 24.12-py3 \
  --target gpu
```

to obtain `ghcr.io/aica-technology/toolkits/cuda:vX.Y.Z-gpu24.12-rc0001`.

### Example 2

As one can imagine, there is a multitude of combinations of CUDA and machine learning libraries that may be needed for a
given task. As such, we can not support all variations in our registry. Therefore, we open-source our library images
and provide helper scripts to build custom configurations. For example, if you want to replicate the Jetson image from
the registries you would have to specify quite a few options and run the build script as follows:

```shell
# For ML libraries (torch for Tegra)
./build.sh --ml-toolkit \
  --target jetson \
  --ubuntu-version 22.04 \
  --python-version 3.10 \
  --tensorrt-image nvcr.io/nvidia/l4t-tensorrt \
  --tensorrt-image-tag r8.6.2-devel

# for CUDA libraries
./build.sh --cuda-toolkit \
  --target jetson \
  --ubuntu-version 22.04 \
  --python-version 3.10 \
  --tensorrt-image nvcr.io/nvidia/l4t-tensorrt \
  --tensorrt-image-tag r8.6.2-devel
```

Those are only few of the available arguments you can provide. Notice how here we specify L4T images as our base. These
commands will generate the following images:

- `ghcr.io/aica-technology/toolkits/cuda:vX.Y.Z-l4t8.6.2-rc0001`
- `ghcr.io/aica-technology/toolkits/ml:vX.Y.Z-l4t8.6.2-rc0001`
