/*
 * Bind mounts a filesystem mountpoint into the target directory,
 * by using the CAP_SYS_ADMIN capability set on the file.
 *
 * Juan RP - 2010/04/26 - Public Domain.
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/mount.h>
#include <sys/capability.h>

void
usage(void)
{
	fprintf(stderr, "Usage: xbps-src-capbmount [-w] <orig> <dest>\n");
	exit(EXIT_FAILURE);
}

int
main(int argc, char **argv)
{
	cap_t cap;
	cap_flag_value_t effective, permitted;
	unsigned long flags;
	int c, rv;
	bool dowrite = false;

	while ((c = getopt(argc, argv, "w")) != -1) {
		switch (c) {
		case 'w':
			dowrite = true;
			break;
		default:
			usage();
		}
	}

	argc -= optind;
	argv += optind;

	if (argc != 2)
		usage();

	cap = cap_get_proc();
	if (cap == NULL) {
		fprintf(stderr, "cap_get_proc() returned %s!\n",
		    strerror(errno));
		exit(EXIT_FAILURE);
	}

	cap_get_flag(cap, CAP_SYS_ADMIN, CAP_EFFECTIVE, &effective);
	cap_get_flag(cap, CAP_SYS_ADMIN, CAP_PERMITTED, &permitted);
	if ((effective != CAP_SET) && (permitted != CAP_SET)) {
		fprintf(stderr, "E: missing 'cap_sys_admin' capability!\n"
		    "Please set it with: setcap cap_sys_admin=ep %s'\n",
		    argv[0]);
		cap_free(cap);
		exit(EXIT_FAILURE);
	}
	cap_free(cap);

	flags = MS_BIND;
	if (!dowrite)
		flags |= MS_RDONLY;

	rv = mount(argv[0], argv[1], "none", flags, NULL);
	if (rv != 0) {
		fprintf(stderr, "E: cannot mount %s into %s: %s\n", argv[0],
		    argv[1], strerror(errno));
		exit(EXIT_FAILURE);
	}

	exit(EXIT_SUCCESS);
}
