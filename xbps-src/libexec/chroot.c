/*
 * chroot() to target directory by using the CAP_CHROOT
 * capability set on the file.
 *
 * Juan RP - 2010/04/26 - Public Domain.
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <limits.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <sys/capability.h>

void
usage(void)
{
	fprintf(stderr, "Usage: xbps-src-capchroot <newroot> <args>\n");
	exit(EXIT_FAILURE);
}

int
main(int argc, char **argv)
{
	cap_t cap;
	cap_flag_value_t effective, permitted;
	struct stat st;
	char *path;

	if (argc < 3)
		usage();

	cap = cap_get_proc();
	if (cap == NULL) {
		fprintf(stderr, "cap_get_proc() returned %s!\n",
		    strerror(errno));
		exit(EXIT_FAILURE);
	}

	cap_get_flag(cap, CAP_SYS_CHROOT, CAP_EFFECTIVE, &effective);
	cap_get_flag(cap, CAP_SYS_CHROOT, CAP_PERMITTED, &permitted);
	if ((effective != CAP_SET) && (permitted != CAP_SET)) {
		fprintf(stderr, "ERROR: missing 'cap_sys_chroot' capability!\n"
		    "Please set it with: setcap cap_sys_chroot=ep %s'\n",
		    argv[0]);
		cap_free(cap);
		exit(EXIT_FAILURE);
	}
	cap_free(cap);

	if ((path = realpath(argv[1], NULL)) == NULL) {
		fprintf(stderr, "ERROR: realpath() %s\n", strerror(errno));
		exit(EXIT_FAILURE);
	}

	/* Disallow chroot to '/' */
	if (strcmp(path, "/") == 0) {
		fprintf(stderr, "ERROR: chroot to / is not allowed!\n");
		exit(EXIT_FAILURE);
	}

	/*
	 * Check that uid/gid owns the dir and has rx perms on the
	 * new target root and it is a directory.
	 */
	if (stat(path, &st) == -1) {
		fprintf(stderr, "ERROR: stat() on %s: %s\n",
		    path, strerror(errno));
		exit(EXIT_FAILURE);
	}
	if (S_ISDIR(st.st_mode) == 0) {
		fprintf(stderr, "ERROR: '%s' not a directory!\n", path);
		exit(EXIT_FAILURE);
	}
	if ((st.st_uid != getuid()) && (st.st_gid != getgid()) &&
	    (st.st_mode & (S_IRUSR|S_IXUSR|S_IRGRP|S_IXGRP))) {
		fprintf(stderr, "ERROR: wrong permissions on %s!\n", path);
		exit(EXIT_FAILURE);
	}
	/* All ok, change root and process argv on the target root dir. */
	if (chroot(path) == -1) {
		fprintf(stderr, "ERROR: chroot() on %s: %s\n", argv[1],
		    strerror(errno));
		exit(EXIT_FAILURE);
	}
	if (chdir("/") == -1) {
		fprintf(stderr, "ERROR: chdir(): %s\n", strerror(errno));
		exit(EXIT_FAILURE);
	}
	argv += 2;
	(void)execvp(argv[0], argv);

	exit(EXIT_FAILURE);
}
