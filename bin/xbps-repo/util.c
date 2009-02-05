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
#include <prop/proplib.h>

#include <xbps_api.h>
#include "util.h"

static void	show_pkg_info(prop_dictionary_t);
static int	show_pkg_namedesc(prop_object_t, void *, bool *);
static int	list_strings_in_array2(prop_object_t, void *, bool *);

static void
show_pkg_info(prop_dictionary_t dict)
{
	prop_object_t obj;
	const char *sep = NULL;
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
		    "", HN_AUTOSCALE, HN_NOSPACE);
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
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("Filename: %s\n", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "filename-sha256");
	if (obj && prop_object_type(obj) == PROP_TYPE_STRING)
		printf("SHA256: %s\n", prop_string_cstring_nocopy(obj));

	obj = prop_dictionary_get(dict, "run_depends");
	if (obj && prop_object_type(obj) == PROP_TYPE_ARRAY) {
		printf("Dependencies:\n\t");
		sep = " ";
		xbps_callback_array_iter_in_dict(dict, "run_depends",
		    list_strings_in_array2, (void *)sep);
		printf("\n\n");
	}

	obj = prop_dictionary_get(dict, "conf_files");
	if (obj && prop_object_type(obj) == PROP_TYPE_ARRAY) {
		printf("Configuration files:\n\t");
		xbps_callback_array_iter_in_dict(dict, "conf_files",
		    list_strings_in_array2, NULL);
		printf("\n");
	}

	obj = prop_dictionary_get(dict, "keep_dirs");
	if (obj && prop_object_type(obj) == PROP_TYPE_ARRAY) {
		printf("Permanent directories:\n\t");
		xbps_callback_array_iter_in_dict(dict, "keep_dirs",
		    list_strings_in_array2, NULL);
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

	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	/* Get the location of pkgindex file. */
	repofile = prop_string_cstring_nocopy(obj);
	assert(repofile != NULL);

	plist = xbps_append_full_path(false, repofile, XBPS_PKGINDEX);
	if (plist == NULL)
		return EINVAL;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		free(plist);
		return EINVAL;
	}

	printf("From %s repository ...\n", repofile);
	xbps_callback_array_iter_in_dict(dict, "packages",
	    show_pkg_namedesc, arg);
	prop_object_release(dict);
	free(plist);

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

	/* Get string for pkg-index.plist with full path. */
	plist = xbps_append_full_path(false, repofile, XBPS_PKGINDEX);
	if (plist == NULL)
		return EINVAL;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL || prop_dictionary_count(dict) == 0) {
		free(plist);
		return EINVAL;
	}

	pkgdict = xbps_find_pkg_in_dict(dict, arg);
	if (pkgdict == NULL) {
		prop_object_release(dict);
		free(plist);
		return XBPS_PKG_ENOTINREPO;
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
	const char *pkgname, *desc, *ver, *string = arg;

	assert(prop_object_type(obj) == PROP_TYPE_DICTIONARY);
	assert(string != NULL);

	prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(obj, "short_desc", &desc);
	prop_dictionary_get_cstring_nocopy(obj, "version", &ver);
	assert(ver != NULL);

	if ((strstr(pkgname, string) || strstr(desc, string)))
		printf("  %s-%s - %s\n", pkgname, ver, desc);

	return 0;
}

static int
list_strings_in_array2(prop_object_t obj, void *arg, bool *loop_done)
{
	static uint16_t count;
	const char *sep;

	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	if (arg == NULL) {
		sep = "\n\t";
		count = 0;
	} else
		sep = (const char *)arg;

	if (count == 4) {
		printf("\n\t");
		count = 0;
	}

	printf("%s%s", prop_string_cstring_nocopy(obj), sep);
	count++;

	return 0;
}

int
list_strings_in_array(prop_object_t obj, void *arg, bool *loop_done)
{
	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	printf("%s\n", prop_string_cstring_nocopy(obj));

	return 0;
}
