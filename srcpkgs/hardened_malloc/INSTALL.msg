
The shared library will be installed at:

	/usr/lib/libhardened_malloc.so
	/usr/lib/libhardened_malloc-light.so

It's will NOT become active on its own. To enable it system-wide, you must preload it.

1. Test it first! Make sure a normal binary still runs:

		LD_PRELOAD=/usr/lib/libhardened_malloc.so /bin/true && echo OK
		LD_PRELOAD=/usr/lib/libhardened_malloc-light.so /bin/true && echo OK

	If that prints OK, the library loads cleanly on this system.

2. Enable system-wide by adding this line to /etc/ld.so.preload
	(create if file doesn't exist):

		/usr/lib/libhardened_malloc.so

		for light variant:
		/usr/lib/libhardened_malloc-light.so

	Per-process alternative (safer to trial): just export LD_PRELOAD as above
	for the programs you want, instead of editing ld.so.preload.

################ WARNING ################

/etc/ld.so.preload is loaded by EVERY dynamically-linked program.
If provided .so files are ever missing or broken while listed there, essential
tools (your shell, sudo , xbps) may fail to start and you can lock
yourself out of a running system.
