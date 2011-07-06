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
 * Umounts a mounted filesystem mountpoint as regular user thanks to
 * the CAP_SYS_ADMIN capability flag set on the file. The following
 * arguments are expected: <masterdir> <dir>.
 *
 * As security measure it only accepts to unmount a mount point
 * when the "status" file has been previously written in the masterdir.
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/param.h>
#include <sys/mount.h>
#include <sys/capability.h>

#define _PROGNAME	"xbps-src-chroot-capumount"

void
usage(void)
{
	fprintf(stderr, "Usage: %s <masterdir> <dir>\n", _PROGNAME);
	exit(EXIT_FAILURE);
}

int
main(int argc, char **argv)
{
	cap_t cap;
	cap_flag_value_t effective, permitted;
	char bindf[PATH_MAX - 1];
	int rv;

	if (argc != 3)
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

	/* Check that status file exists in masterdir */
	rv = snprintf(bindf, sizeof(bindf), "%s/.%s_mount_bind_done",
	    argv[1], argv[2]);
	if (rv < 0 || rv >= sizeof(bindf))
		exit(EXIT_FAILURE);

	if (access(bindf, R_OK) == -1) {
		fprintf(stderr, "E: cannot umount %s/%s, missing "
		    "status file\n", argv[1], argv[2]);
		exit(EXIT_FAILURE);
	}

	/* Security check passed, continue mounting */
	rv = snprintf(bindf, sizeof(bindf), "%s/%s", argv[1], argv[2]);
	if (rv < 0 || rv >= sizeof(bindf))
		exit(EXIT_FAILURE);

	if ((rv = umount(bindf)) != 0) {
		fprintf(stderr, "E: cannot umount %s: %s\n", argv[1],
		    strerror(errno));
		exit(EXIT_FAILURE);
	}

	exit(EXIT_SUCCESS);
}
