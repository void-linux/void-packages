/*-
 * Copyright (c) 2008 Juan Romero Pardines.
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

#include <xbps_api.h>

const char *
xbps_get_pkg_version(const char *pkg)
{
	const char *tmp;

	/* Get the required version */
	tmp = strrchr(pkg, '-');
	assert(tmp != NULL);
	return tmp + 1; /* skip first '-' */
}

char *
xbps_get_pkg_name(const char *pkg)
{
	const char *tmp;
	char *pkgname;
	size_t len = 0;

	/* Get the required version */
	tmp = strrchr(pkg, '-');
	assert(tmp != NULL);
	len = strlen(pkg) - strlen(tmp) + 1;

	/* Get package name */
	pkgname = malloc(len);
	memcpy(pkgname, pkg, len - 1);
	pkgname[len - 1] = '\0';

	return pkgname;
}

bool
xbps_pkg_has_rundeps(prop_dictionary_t pkg)
{
	prop_array_t array;

	assert(pkg != NULL);
	array = prop_dictionary_get(pkg, "run_depends");
	if (array && prop_array_count(array) > 0)
		return true;

	return false;
}

bool
xbps_append_full_path(char *buf, const char *root, const char *plistf)
{
	const char *env, *tmp;
	size_t len = 0;

	assert(buf != NULL);
	assert(plistf != NULL);

	if (root)
		env = root;
	else {
		env = getenv("XBPS_META_PATH");
		if (env == NULL)
			env = XBPS_META_PATH;
	}

	tmp = strncpy(buf, env, PATH_MAX - 1);
	if (sizeof(*tmp) >= PATH_MAX) {
		errno = ENOSPC;
		return false;
	}

	len = strlen(buf);
	buf[len + 1] = '\0';
	if (buf[len - 2] != '/')
		strncat(buf, "/", 1);
	strncat(buf, plistf, sizeof(buf) - strlen(buf) - 1);

	return true;
}
