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
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <xbps_api.h>

/*
 * Configure a package that is currently unpacked. This
 * runs the post INSTALL action if required and updates the
 * package state to installed.
 */
int
xbps_configure_pkg(const char *pkgname)
{
	prop_dictionary_t pkgd;
	const char *rootdir, *version;
	char *buf;
	int rv = 0, flags = 0;
	pkg_state_t state = 0;
	bool reconfigure = false;

	assert(pkgname != NULL);

	rootdir = xbps_get_rootdir();
	flags = xbps_get_flags();

	if ((rv = xbps_get_pkg_state_installed(pkgname, &state)) != 0)
		return rv;

	if (state == XBPS_PKG_STATE_INSTALLED) {
		if ((flags & XBPS_FLAG_FORCE) == 0)
			return 0;

		reconfigure = true;
	} else if (state != XBPS_PKG_STATE_UNPACKED)
		return EINVAL;

	pkgd = xbps_find_pkg_installed_from_plist(pkgname);
	if (pkgd == NULL)
		return ENOENT;

	prop_dictionary_get_cstring_nocopy(pkgd, "version", &version);
	prop_object_release(pkgd);

	printf("%sonfiguring package %s-%s...\n",
	    reconfigure ? "Rec" : "C", pkgname, version);

	buf = xbps_xasprintf(".%s/metadata/%s/INSTALL",
	    XBPS_META_PATH, pkgname);
	if (buf == NULL)
		return errno;

	if (access(buf, R_OK) == 0) {
		if (strcmp(rootdir, "") == 0)
			rootdir = "/";

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
