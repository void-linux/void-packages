Steam on x86_64 requires support for OpenGL/Vulkan in 32bits mode,
the 32bit packages are available in the `multilib` repository.

	# xbps-install -Syv void-repo-multilib{,-nonfree}
	# xbps-install -S

Generic (for all systems):

	- libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit

For users of the open source drivers:

	- mesa-dri-32bit

For users of the proprietary NVIDIA driver:

	- nvidia-libs-32bit (latest nvidia package)
	- nvidia390-libs-32bit (latest previous package)
	- nvidia340-libs-32bit (latest package for old GPUs)

For mesa users this would result in:

	# xbps-install -Syv libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit mesa-dri-32bit
