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

#include <xbps_api.h>

static int
add_pkg_into_reqby(prop_dictionary_t pkgd, const char *reqname)
{
	prop_array_t array;
	prop_string_t reqstr;
	bool alloc = false;

	array = prop_dictionary_get(pkgd, "requiredby");
	if (array == NULL) {
		alloc = true;
		array = prop_array_create();
		if (array == NULL)
			return ENOMEM;
	}

	if (xbps_find_string_in_array(array, reqname))
		return EEXIST;

	reqstr = prop_string_create_cstring(reqname);
	if (reqstr == NULL) {
		if (alloc)
			prop_object_release(array);
		return errno;
	}

	if (!xbps_add_obj_to_array(array, reqstr)) {
		if (alloc)
			prop_object_release(array);

		prop_object_release(reqstr);
		return EINVAL;
	}

	if (!alloc)
		return 0;

	if (!xbps_add_obj_to_dict(pkgd, array, "requiredby")) {
		if (alloc)
			prop_object_release(array);

		return EINVAL;
	}

	return 0;
}

static int
remove_pkg_from_reqby(prop_object_t obj, void *arg, bool *loop_done)
{
	prop_array_t array;
	prop_object_t obj2;
	prop_object_iterator_t iter;
	const char *pkgname = arg;
	char *curpkgname;
	size_t idx = 0;
	bool found = false;

	(void)loop_done;

	array = prop_dictionary_get(obj, "requiredby");
	if (array == NULL || prop_array_count(array) == 0)
		return 0;

	iter = prop_array_iterator(array);
	if (iter == NULL)
		return ENOMEM;

	while ((obj2 = prop_object_iterator_next(iter)) != NULL) {
		curpkgname =
		    xbps_get_pkg_name(prop_string_cstring_nocopy(obj2));
		if (strcmp(curpkgname, pkgname) == 0) {
			free(curpkgname);
			found = true;
			break;
		}
		free(curpkgname);
		idx++;
	}
	prop_object_iterator_release(iter);
	if (found)
		prop_array_remove(array, idx);

	return 0;
}

int
xbps_requiredby_pkg_remove(const char *pkgname)
{
	prop_dictionary_t dict;
	const char *rootdir;
	char *plist;
	int rv = 0;

	rootdir = xbps_get_rootdir();
	plist = xbps_xasprintf("%s/%s/%s", rootdir,
	    XBPS_META_PATH, XBPS_REGPKGDB);
	if (plist == NULL)
		return EINVAL;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		free(plist);
		return errno;
	}

	rv = xbps_callback_array_iter_in_dict(dict, "packages",
	    remove_pkg_from_reqby, __UNCONST(pkgname));
	if (rv == 0) {
		if (!prop_dictionary_externalize_to_file(dict, plist))
			rv = errno;
	}

	prop_object_release(dict);
	free(plist);

	return rv;
}

int
xbps_requiredby_pkg_add(prop_array_t regar, prop_dictionary_t pkg)
{
	prop_array_t rdeps;
	prop_object_t obj, obj2;
	prop_object_iterator_t iter, iter2;
	const char *reqname, *pkgname, *version;
	char *rdepname, *fpkgn;
	int rv = 0;

	prop_dictionary_get_cstring_nocopy(pkg, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(pkg, "version", &version);
	fpkgn = xbps_xasprintf("%s-%s", pkgname, version);
	if (fpkgn == NULL)
		return ENOMEM;

	rdeps = prop_dictionary_get(pkg, "run_depends");
	if (rdeps == NULL || prop_array_count(rdeps) == 0) {
		free(fpkgn);
		return EINVAL;
	}

	iter = prop_array_iterator(rdeps);
	if (iter == NULL) {
		free(fpkgn);
		return ENOMEM;
	}

	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		rdepname = xbps_get_pkg_name(prop_string_cstring_nocopy(obj));
		iter2 = prop_array_iterator(regar);
		if (iter2 == NULL) {
			free(rdepname);
			rv = ENOMEM;
			goto out;
		}

		/*
		 * Iterate over the array to find the dictionary for the
		 * current run dependency.
		 */
		while ((obj2 = prop_object_iterator_next(iter2)) != NULL) {
			prop_dictionary_get_cstring_nocopy(obj2, "pkgname",
			    &reqname);
			if (strcmp(rdepname, reqname) == 0) {
				rv = add_pkg_into_reqby(obj2, fpkgn);
				if (rv != 0) {
					free(rdepname);
					prop_object_iterator_release(iter2);
					goto out;
				}
				break;
			}
		}
		prop_object_iterator_release(iter2);
		free(rdepname);
	}

out:
	free(fpkgn);
	prop_object_iterator_release(iter);

	return rv;
}
