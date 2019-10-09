Steam on x86_64 requires support for OpenGL in 32bits mode, install any
of the following packages for your hardware:

For users of the open source drivers:

	- mesa-ati-dri-32bit + libGL-32bit (AMD)
	- mesa-intel-dri-32bit + libGL-32bit (Intel)
	- mesa-nouveau-dri-32bit + libGL-32bit (NVIDIA)

For users of the proprietary NVIDIA driver:

	- nvidia-libs-32bit (latest nvidia package)
	- nvidia-stable-libs-32bit (latest stable package)
	- nvidia304-libs-32bit (latest package for old GPUs)

For users of the proprietary AMD driver:

	- catalyst-libs-32bit

Do not forget to enable the `multilib` and `multilib/nonfree` repositories
in xbps, i.e:

	# xbps-install -Syv void-repo-multilib{,-nonfree}
	# xbps-install -S

to install any of those packages mentioned above.
