If the `rke2-cleanup.sh` script is not run,
then certain files may still be present on
disk.

Configuration files may still be stored in:

	/etc/rancher/rke2
	/etc/rancher/node

Stored RKE2 data may still be stored in:

	/var/lib/rancher/rke2

It's left for data preservation's sake,
but cleanup is recommended for a full
removal.
