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
 * chroot() to target directory by using the CAP_CHROOT
 * capability set on the file.
 *
 * As security measure it only allows to chroot when the target directory
 * is owned by the same user executing the process and it has read/write
 * permission on it.
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

#define _PROGNAME	"xbps-src-capchroot"

void
usage(void)
{
	fprintf(stderr, "Usage: %s <newroot> <args>\n", _PROGNAME);
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
