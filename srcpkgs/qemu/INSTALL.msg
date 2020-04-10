To enable KVM your user must be added to the 'kvm' group:

	$ sudo usermod -aG kvm <username>

Don't forget to load the appropiate KVM module for your CPU (x86 only):

	$ sudo modprobe kvm-amd # for AMD CPUs
	$ sudo modprobe kvm-intel # for Intel CPUs
