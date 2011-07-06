/*-
 * Copyright (c) 2010-2011 Juan Romero Pardines.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Bind mounts a filesystem mountpoint into the target directory,
 * by using the CAP_SYS_ADMIN capability set on the program.
 *
 * Only mounts are possible when user running the process owns
 * the target directory and has read/write permission on it.
 *
 * Mounts are also mounted with nosuid for security meassures.
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/capability.h>

#define _PROGNAME	"xbps-src-chroot-capmount"

void
usage(void)
{
	fprintf(stderr, "Usage: %s [-w] <orig> <dest>\n", _PROGNAME);
	exit(EXIT_FAILURE);
}

int
main(int argc, char **argv)
{
	cap_t cap;
	cap_flag_value_t effective, permitted;
	struct stat st;
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

	/*
	 * Bind mount with nosuid.
	 */
	flags = MS_BIND | MS_NOSUID;
	if (!dowrite)
		flags |= MS_RDONLY;

	/*
	 * Check that uid/gid owns the dir and has rx perms on it.
	 */
	if (stat(argv[1], &st) == -1) {
		fprintf(stderr, "ERROR: stat() on %s: %s\n",
		    argv[1], strerror(errno));
		exit(EXIT_FAILURE);
	}
	if ((st.st_uid != getuid()) && (st.st_gid != getgid()) &&
	    (st.st_mode & (S_IRUSR|S_IXUSR|S_IRGRP|S_IXGRP))) {
		fprintf(stderr, "ERROR: wrong permissions on %s!\n", argv[1]);
		exit(EXIT_FAILURE);
	}

	rv = mount(argv[0], argv[1], "none", flags, NULL);
	if (rv != 0) {
		fprintf(stderr, "E: cannot mount %s into %s: %s\n", argv[0],
		    argv[1], strerror(errno));
		exit(EXIT_FAILURE);
	}

	exit(EXIT_SUCCESS);
}
