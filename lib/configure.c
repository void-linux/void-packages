/*-
 * Copyright (c) 2009 Juan Romero Pardines.
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

#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <limits.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

#include <xbps_api.h>

/*
 * Configure a package that is currently unpacked. This
 * runs the post INSTALL action if required and updates the
 * package state to installed.
 */
int
xbps_configure_pkg(const char *pkgname, const char *version)
{
	const char *rootdir;
	char *buf;
	int rv = 0;
	pkg_state_t state = 0;

	assert(pkgname != NULL);
	assert(version != NULL);
	rootdir = xbps_get_rootdir();

	if ((rv = xbps_get_pkg_state_installed(pkgname, &state)) != 0)
		return rv;

	/*
	 * If package is already installed do nothing, and only
	 * continue if it's unpacked.
	 */
	if (state == XBPS_PKG_STATE_INSTALLED)
		return 0;
	else if (state != XBPS_PKG_STATE_UNPACKED)
		return EINVAL;

	buf = xbps_xasprintf(".%s/metadata/%s/INSTALL",
	    XBPS_META_PATH, pkgname);
	if (buf == NULL)
		return errno;

	if (access(buf, R_OK) == 0) {
		if (chdir(rootdir) == -1)
			return errno;

		if ((rv = xbps_file_chdir_exec(rootdir, buf, "post",
		     pkgname, version, NULL)) != 0) {
			free(buf);
			printf("%s: post INSTALL action returned: %s\n",
			    pkgname, strerror(errno));
			return rv;
		}
	} else {
		if (errno != ENOENT) {
			free(buf);
			return errno;
		}
	}
	free(buf);

	return xbps_set_pkg_state_installed(pkgname, XBPS_PKG_STATE_INSTALLED);
}
