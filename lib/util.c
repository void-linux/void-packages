/*-
 * Copyright (c) 2008-2009 Juan Romero Pardines.
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
#include <stdarg.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <ctype.h>
#include <limits.h>
#include <sys/utsname.h>

#include <xbps_api.h>

static bool	question(bool, const char *, va_list);

static const char *rootdir;
static int flags;

char *
xbps_get_file_hash(const char *file)
{
	SHA256_CTX ctx;
	char *hash;
	uint8_t buf[BUFSIZ * 20], digest[SHA256_DIGEST_STRING_LENGTH];
	ssize_t bytes;
	int fd;

	if ((fd = open(file, O_RDONLY)) == -1)
		return NULL;

	SHA256_Init(&ctx);
	while ((bytes = read(fd, buf, sizeof(buf))) > 0)
		SHA256_Update(&ctx, buf, (size_t)bytes);
	hash = strdup(SHA256_End(&ctx, digest));
	(void)close(fd);

	return hash;
}

int
xbps_check_file_hash(const char *path, const char *sha256)
{
	char *res;

	res = xbps_get_file_hash(path);
	if (res == NULL)
		return errno;

	if (strcmp(sha256, res)) {
		free(res);
		return ERANGE;
	}
	free(res);

	return 0;
}

int
xbps_check_pkg_file_hash(prop_dictionary_t pkgd, const char *repoloc)
{
	const char *sha256, *arch, *filename;
	char *binfile;
	int rv = 0;

	assert(repoloc != NULL);

	if (!prop_dictionary_get_cstring_nocopy(pkgd, "filename", &filename))
		return EINVAL;

	if (!prop_dictionary_get_cstring_nocopy(pkgd, "filename-sha256",
	    &sha256))
		return EINVAL;

	if (!prop_dictionary_get_cstring_nocopy(pkgd, "architecture", &arch))
		return EINVAL;

	binfile = xbps_xasprintf("%s/%s/%s", repoloc, arch, filename);
	if (binfile == NULL)
		return EINVAL;

	rv = xbps_check_file_hash(binfile, sha256);
	free(binfile);

	return rv;
}

int
xbps_check_is_installed_pkg(const char *pkg)
{
	prop_dictionary_t dict;
	const char *reqver, *instver;
	char *pkgname;
	int rv = 0;
	pkg_state_t state = 0;

	assert(pkg != NULL);

	pkgname = xbps_get_pkg_name(pkg);
	reqver = xbps_get_pkg_version(pkg);

	dict = xbps_find_pkg_installed_from_plist(pkgname);
	if (dict == NULL) {
		free(pkgname);
		return -1; /* not installed */
	}

	/*
	 * Check that package state is fully installed, not
	 * unpacked or something else.
	 */
	if (xbps_get_pkg_state_installed(pkgname, &state) != 0) {
		free(pkgname);
		return -1;
	}
	free(pkgname);

	if (state != XBPS_PKG_STATE_INSTALLED)
		return -1;

	/* Get version from installed package */
	prop_dictionary_get_cstring_nocopy(dict, "version", &instver);

	/* Compare installed and required version. */
	rv = xbps_cmpver(instver, reqver);

	prop_object_release(dict);

	return rv;
}

bool
xbps_check_is_installed_pkgname(const char *pkgname)
{
	prop_dictionary_t pkgd;

	assert(pkgname != NULL);

	pkgd = xbps_find_pkg_installed_from_plist(pkgname);
	if (pkgd) {
		prop_object_release(pkgd);
		return true;
	}

	return false;
}

const char *
xbps_get_pkg_version(const char *pkg)
{
	const char *tmp;

	assert(pkg != NULL);

	/* Get the required version */
	tmp = strrchr(pkg, '-');
	if (tmp == NULL)
		return NULL;

	return tmp + 1; /* skip first '-' */
}

const char *
xbps_get_pkg_revision(const char *pkg)
{
	const char *tmp;

	assert(pkg != NULL);

	/* Get the required revision */
	tmp = strrchr(pkg, '_');
	if (tmp == NULL)
		return NULL;

	return tmp + 1; /* skip first '_' */
}

char *
xbps_get_pkg_name(const char *pkg)
{
	const char *tmp;
	char *pkgname;
	size_t len = 0;

	assert(pkg != NULL);

	/* Get package name */
	tmp = strrchr(pkg, '-');
	if (tmp == NULL)
		return NULL;

	len = strlen(pkg) - strlen(tmp) + 1;

	pkgname = malloc(len);
	memcpy(pkgname, pkg, len - 1);
	pkgname[len - 1] = '\0';

	return pkgname;
}

char *
xbps_get_pkg_index_plist(const char *path)
{
	struct utsname un;

	assert(path != NULL);

	if (uname(&un) == -1)
		return NULL;

	return xbps_xasprintf("%s/%s/%s", path, un.machine, XBPS_PKGINDEX);
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

void
xbps_set_rootdir(const char *dir)
{
	assert(dir != NULL);
	rootdir = dir;
}

const char *
xbps_get_rootdir(void)
{
	if (rootdir == NULL)
		rootdir = "";

	return rootdir;
}

void
xbps_set_flags(int lflags)
{
	flags = lflags;
}

int
xbps_get_flags(void)
{
	return flags;
}

char *
xbps_xasprintf(const char *fmt, ...)
{
	va_list ap;
	char *buf;

	va_start(ap, fmt);
	if (vasprintf(&buf, fmt, ap) == -1)
		return NULL;
	va_end(ap);

	return buf;
}

/*
 * The following functions were taken from pacman (src/pacman/util.c)
 * Copyright (c) 2002-2007 by Judd Vinet <jvinet@zeroflux.org>
 */
bool
xbps_yesno(const char *fmt, ...)
{
	va_list ap;
	bool res;

	va_start(ap, fmt);
	res = question(1, fmt, ap);
	va_end(ap);

	return res;
}

bool
xbps_noyes(const char *fmt, ...)
{
	va_list ap;
	bool res;

	va_start(ap, fmt);
	res = question(0, fmt, ap);
	va_end(ap);

	return res;
}

static char *
strtrim(char *str)
{
	char *pch = str;

	if (str == NULL || *str == '\0')
		return str;

	while (isspace((unsigned char)*pch))
		pch++;

	if (pch != str)
		memmove(str, pch, (strlen(pch) + 1));

	if (*str == '\0')
		return str;

	pch = (str + (strlen(str) - 1));
	while (isspace((unsigned char)*pch))
		pch--;

	*++pch = '\0';

	return str;
}

static bool
question(bool preset, const char *fmt, va_list ap)
{
	char response[32];

	vfprintf(stderr, fmt, ap);
	if (preset)
		fprintf(stderr, " %s ", "[Y/n]");
	else
		fprintf(stderr, " %s ", "[y/N]");

	if (fgets(response, 32, stdin)) {
		(void)strtrim(response);
		if (strlen(response) == 0)
			return preset;

		if ((strcasecmp(response, "y") == 0) ||
		    (strcasecmp(response, "yes") == 0))
			return true;
		else if ((strcasecmp(response, "n") == 0) ||
			 (strcasecmp(response, "no") == 0))
			return false;
	}
	return false;
}
