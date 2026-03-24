Starting with 595.xx, Void now uses the "open" DKMS modules. The "open" drivers
only support Turing and later GPUs. For a complete list, refer to the following
list of compatible devices.

    https://github.com/nvidia/open-gpu-kernel-modules#compatible-gpus

If you have an older GPU, you will need to switch to the 580.xx driver branch,
supported by the `nvidia580` family of packages.
