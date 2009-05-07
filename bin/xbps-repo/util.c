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
#include <string.h>
#include <errno.h>
#include <fnmatch.h>
#include <limits.h>
#include <prop/proplib.h>

#include <xbps_api.h>
#include "util.h"

struct show_files_cb {
	const char *destdir;
	bool check_hash;
};

static void	show_pkg_info(prop_dictionary_t);
static int	show_pkg_files(prop_object_t, void *, bool *);
static int	show_pkg_namedesc(prop_object_t, void *, bool *);

static void
show_pkg_info(prop_dictionary_t dict)
{
	prop_object_t obj;
	const char *sep;
	char size[64];
	int rv = 0;

	assert(dict != NULL);
	assert(prop_dictionary_count(dict) != 0);

	obj = prop_dictionary_get(dict, "pkgname");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("Package: %s\n", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "installed_size");
	if (obj && prop_object_type(obj) == PROP_TYPE_NUMBER) {
		printf("Installed size: ");
		rv = xbps_humanize_number(size, 5,
		    (int64_t)prop_number_unsigned_integer_value(obj),
		    "", HN_AUTOSCALE, HN_B|HN_DECIMAL|HN_NOSPACE);
		if (rv == -1)
			printf("%ju\n",
			    prop_number_unsigned_integer_value(obj));
		else
			printf("%s\n", size);
	}

	obj = prop_dictionary_get(dict, "maintainer");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("Maintainer: %s\n", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "architecture");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("Architecture: %s\n", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "version");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("Version: %s\n", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "filename");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING) {
		printf("Filename: %s", prop_string_cstring_nocopy(obj));
		obj = prop_dictionary_get(dict, "filename-size");
		if (obj && prop_object_type(obj) == PROP_TYPE_NUMBER) {
			rv = xbps_humanize_number(size, 5,
			    (int64_t)prop_number_unsigned_integer_value(obj),
			    "", HN_AUTOSCALE, HN_B|HN_DECIMAL|HN_NOSPACE);
			if (rv == -1)
				printf(" (size: %ju)\n",
				    prop_number_unsigned_integer_value(obj));
			else
				printf(" (size: %s)\n", size);
		} else
			printf("\n");
	}

	obj = prop_dictionary_get(dict, "filename-sha256");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("SHA256: %s\n", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "run_depends");
	if (obj && prop_object_type(obj) == PROP_TYPE_ARRAY) {
		printf("Dependencies:\n");
		(void)xbps_callback_array_iter_in_dict(dict, "run_depends",
		    list_strings_in_array, NULL);
		printf("\n\n");
	}

	obj = prop_dictionary_get(dict, "conf_files");
	if (obj && prop_object_type(obj) == PROP_TYPE_ARRAY) {
		printf("Configuration files:\n");
		sep = "  ";
		(void)xbps_callback_array_iter_in_dict(dict, "conf_files",
		    list_strings_sep_in_array, __UNCONST(sep));
		printf("\n");
	}

	obj = prop_dictionary_get(dict, "keep_dirs");
	if (obj && prop_object_type(obj) == PROP_TYPE_ARRAY) {
		printf("Permanent directories:\n");
		sep = "  ";
		(void)xbps_callback_array_iter_in_dict(dict, "keep_dirs",
		    list_strings_sep_in_array, __UNCONST(sep));
		printf("\n");
	}

	obj = prop_dictionary_get(dict, "short_desc");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("Description: %s", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "long_desc");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf(" %s\n", prop_string_cstring_nocopy(obj));
}

int
search_string_in_pkgs(prop_object_t obj, void *arg, bool *loop_done)
{
	prop_dictionary_t dict;
	const char *repofile;
	char *plist;

	(void)loop_done;

	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	/* Get the location of pkgindex file. */
	repofile = prop_string_cstring_nocopy(obj);
	assert(repofile != NULL);

	plist = xbps_get_pkg_index_plist(repofile);
	if (plist == NULL) {
		errno = ENOENT;
		return 0;
	}

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		free(plist);
		return 0;
	}

	printf("From %s repository ...\n", repofile);
	xbps_callback_array_iter_in_dict(dict, "packages",
	    show_pkg_namedesc, arg);
	prop_object_release(dict);
	free(plist);

	return 0;
}

int
show_pkg_info_from_metadir(const char *pkgname)
{
	prop_dictionary_t pkgd;
	const char *rootdir;
	char *plist;

	rootdir = xbps_get_rootdir();
	plist = xbps_xasprintf("%s/%s/metadata/%s/%s", rootdir,
	    XBPS_META_PATH, pkgname, XBPS_PKGPROPS);
	if (plist == NULL)
		return EINVAL;

	pkgd = prop_dictionary_internalize_from_file(plist);
	if (pkgd == NULL) {
		free(plist);
		return errno;
	}

	show_pkg_info(pkgd);
	prop_object_release(pkgd);
	free(plist);

	return 0;
}

int
show_pkg_files_from_metadir(const char *pkgname, bool hash)
{
	prop_dictionary_t pkgd;
	struct show_files_cb sfc;
	const char *destdir = xbps_get_rootdir();
	char *plist;
	int rv = 0;

	plist = xbps_xasprintf("%s/%s/metadata/%s/%s", destdir,
	    XBPS_META_PATH, pkgname, XBPS_PKGFILES);
	if (plist == NULL)
		return EINVAL;

	pkgd = prop_dictionary_internalize_from_file(plist);
	if (pkgd == NULL) {
		free(plist);
		return errno;
	}

	sfc.destdir = destdir;
	sfc.check_hash = hash;
	rv = xbps_callback_array_iter_in_dict(pkgd, "filelist",
	    show_pkg_files, (void *)&sfc);
	prop_object_release(pkgd);
	free(plist);

	return rv;
}

static int
show_pkg_files(prop_object_t obj, void *arg, bool *loop_done)
{
	struct show_files_cb *sfc = arg;
	const char *file = NULL, *sha256, *type;
	char *path = NULL;
	int rv = 0;

	(void)loop_done;

	prop_dictionary_get_cstring_nocopy(obj, "file", &file);
	prop_dictionary_get_cstring_nocopy(obj, "type", &type);
	if (strcmp(type, "dir") == 0)
		return 0;

	if (sfc->check_hash == false && file != NULL) {
		printf("%s\n", file);
		return 0;
	}

	if (strcmp(type, "link") == 0)
		return 0;

	if (sfc->check_hash && file != NULL) {
		printf("%s", file);
		if (sfc->destdir) {
			path = xbps_xasprintf("%s/%s", sfc->destdir, file);
			if (path == NULL)
				return EINVAL;
		}

		prop_dictionary_get_cstring_nocopy(obj, "sha256", &sha256);
		if (sfc->destdir)
			rv = xbps_check_file_hash(path, sha256);
		else
			rv = xbps_check_file_hash(file, sha256);

		if (rv != 0 && rv != ERANGE)
			printf(" (can't check: %s)", strerror(rv));
		else if (rv == ERANGE)
			printf("  WARNING! SHA256 HASH MISMATCH!");

		printf("\n");
		if (sfc->destdir)
			free(path);
	}

	return 0;
}

int
show_pkg_info_from_repolist(prop_object_t obj, void *arg, bool *loop_done)
{
	prop_dictionary_t dict, pkgdict;
	prop_string_t oloc;
	const char *repofile, *repoloc;
	char *plist;

	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	/* Get the location */
	repofile = prop_string_cstring_nocopy(obj);

	plist = xbps_get_pkg_index_plist(repofile);
	if (plist == NULL)
		return EINVAL;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL || prop_dictionary_count(dict) == 0) {
		free(plist);
		errno = ENOENT;
		return 0;
	}

	pkgdict = xbps_find_pkg_in_dict(dict, "packages", arg);
	if (pkgdict == NULL) {
		prop_object_release(dict);
		free(plist);
		errno = ENOENT;
		return 0;
	}

	oloc = prop_dictionary_get(dict, "location-remote");
	if (oloc == NULL)
		oloc = prop_dictionary_get(dict, "location-local");

	if (oloc && prop_object_type(oloc) == PROP_TYPE_STRING)
		repoloc = prop_string_cstring_nocopy(oloc);
	else {
		prop_object_release(dict);
		free(plist);
		return EINVAL;
	}

	printf("Repository: %s\n", repoloc);
	show_pkg_info(pkgdict);
	*loop_done = true;
	prop_object_release(dict);
	free(plist);

	return 0;
}

static int
show_pkg_namedesc(prop_object_t obj, void *arg, bool *loop_done)
{
	const char *pkgname, *desc, *ver, *pattern = arg;

	(void)loop_done;

	assert(prop_object_type(obj) == PROP_TYPE_DICTIONARY);
	assert(pattern != NULL);

	prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(obj, "short_desc", &desc);
	prop_dictionary_get_cstring_nocopy(obj, "version", &ver);
	assert(ver != NULL);

	if ((fnmatch(pattern, pkgname, 0) == 0) ||
	    (fnmatch(pattern, desc, 0) == 0))
		printf(" %s-%s - %s\n", pkgname, ver, desc);

	return 0;
}

int
list_strings_in_array(prop_object_t obj, void *arg, bool *loop_done)
{
	static size_t cols;
	static bool first;

	(void)arg;
	(void)loop_done;

	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	cols += strlen(prop_string_cstring_nocopy(obj)) + 4;
	if (cols <= 80) {
		if (first == false) {
			printf("  ");
			first = true;
		}
	} else {
		printf("\n  ");
		cols = strlen(prop_string_cstring_nocopy(obj)) + 4;
	}
	printf("%s ", prop_string_cstring_nocopy(obj));

	return 0;
}

int
list_strings_sep_in_array(prop_object_t obj, void *arg, bool *loop_done)
{
	const char *sep = arg;

	(void)loop_done;

	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	printf("%s%s\n", sep ? sep : "", prop_string_cstring_nocopy(obj));

	return 0;
}
