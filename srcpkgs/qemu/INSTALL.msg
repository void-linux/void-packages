To enable KVM your user must be added to the 'kvm' group:

	$ usermod -aG kvm <username>

Don't forget to load the appropiate KVM module for your CPU (x86 only):

	$ modprobe kvm-amd # for AMD CPUs
	$ modprobe kvm-intel # for Intel CPUs
