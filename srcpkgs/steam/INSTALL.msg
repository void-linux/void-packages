Steam on x86_64 requires support for OpenGL in 32bits mode, install any
of the following packages for your hardware:

Generic:

	- libgcc-32bit libstdc++-32bit libglvnd-32bit

For users of the open source drivers:

	- mesa-ati-dri-32bit (AMD)
	- mesa-intel-dri-32bit (Intel)
	- mesa-nouveau-dri-32bit (NVIDIA)

For users of the proprietary NVIDIA driver:

	- nvidia-libs-32bit (latest nvidia package)
	- nvidia390-libs-32bit (latest previous package)
	- nvidia340-libs-32bit (latest package for old GPUs)

Do not forget to enable the `multilib` and `multilib/nonfree` repositories
in xbps, i.e:

	# xbps-install -Syv void-repo-multilib{,-nonfree}
	# xbps-install -S

to install any of those packages mentioned above.
