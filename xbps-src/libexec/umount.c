/*
 * Umounts a previously bind mounted filesystem mountpoint,
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
	fprintf(stderr, "Usage: xbps-src-capbumount <dest>\n");
	exit(EXIT_FAILURE);
}

int
main(int argc, char **argv)
{
	cap_t cap;
	cap_flag_value_t effective, permitted;
	int rv;

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

	if ((rv = umount(argv[1])) != 0) {
		fprintf(stderr, "E: cannot umount %s: %s\n", argv[0],
		    strerror(errno));
		exit(EXIT_FAILURE);
	}

	exit(EXIT_SUCCESS);
}
