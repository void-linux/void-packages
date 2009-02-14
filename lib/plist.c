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

bool
xbps_add_obj_to_dict(prop_dictionary_t dict, prop_object_t obj,
		       const char *key)
{
	assert(dict != NULL);
	assert(obj != NULL);
	assert(key != NULL);

	if (!prop_dictionary_set(dict, key, obj)) {
		prop_object_release(dict);
		return false;
	}

	prop_object_release(obj);
	return true;
}

bool
xbps_add_obj_to_array(prop_array_t array, prop_object_t obj)
{
	assert(array != NULL);
	assert(obj != NULL);

	if (!prop_array_add(array, obj)) {
		prop_object_release(array);
		return false;
	}

	prop_object_release(obj);
	return true;
}

int
xbps_callback_array_iter_in_repolist(int (*fn)(prop_object_t, void *, bool *),
				     void *arg)
{
	prop_dictionary_t repolistd;
	char *plist;
	int rv = 0;

	assert(fn != NULL);

	plist = xbps_append_full_path(true, NULL, XBPS_REPOLIST);
	if (plist == NULL)
		return EINVAL;

	/*
	 * Get the dictionary with the list of registered repositories.
	 */
	repolistd = prop_dictionary_internalize_from_file(plist);
	if (repolistd == NULL)
                return EINVAL;

	/*
	 * Iterate over the repository pool and run the associated
	 * callback function. The loop is stopped when the bool
	 * argument is true or the cb returns non 0.
	 */
	rv = xbps_callback_array_iter_in_dict(repolistd, "repository-list",
		fn, arg);
	prop_object_release(repolistd);
	free(plist);

	return rv;
}

int
xbps_callback_array_iter_in_dict(prop_dictionary_t dict, const char *key,
				 int (*fn)(prop_object_t, void *, bool *),
				 void *arg)
{
	prop_object_iterator_t iter;
	prop_object_t obj;
	int rv = 0;
	bool cbloop_done = false;

	assert(dict != NULL);
	assert(key != NULL);
	assert(fn != NULL);

	iter = xbps_get_array_iter_from_dict(dict, key);
	if (iter == NULL)
		return EINVAL;

	while ((obj = prop_object_iterator_next(iter))) {
		rv = (*fn)(obj, arg, &cbloop_done);
		if (rv != 0 || cbloop_done)
			break;
	}

	prop_object_iterator_release(iter);
	return rv;
}

prop_dictionary_t
xbps_find_pkg_from_plist(const char *plist, const char *pkgname)
{
	prop_dictionary_t dict;
	prop_dictionary_t obj, res;

	assert(plist != NULL);
	assert(pkgname != NULL);

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		errno = ENOENT;
		return NULL;
	}

	obj = xbps_find_pkg_in_dict(dict, "packages", pkgname);
	if (obj == NULL) {
		prop_object_release(dict);
		errno = ENOENT;
		return NULL;
	}

	res = prop_dictionary_copy(obj);
	prop_object_release(dict);

	return res;
}

prop_dictionary_t
xbps_find_pkg_in_dict(prop_dictionary_t dict, const char *key,
		      const char *pkgname)
{
	prop_object_iterator_t iter;
	prop_object_t obj;
	const char *dpkgn;

	assert(dict != NULL);
	assert(pkgname != NULL);
	assert(key != NULL);

	iter = xbps_get_array_iter_from_dict(dict, key);
	if (iter == NULL)
		return NULL;

	while ((obj = prop_object_iterator_next(iter))) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &dpkgn);
		if (strcmp(dpkgn, pkgname) == 0)
			break;
	}
	prop_object_iterator_release(iter);

	return obj;
}

bool
xbps_find_string_in_array(prop_array_t array, const char *val)
{
	prop_object_iterator_t iter;
	prop_object_t obj;

	assert(array != NULL);
	assert(val != NULL);

	iter = prop_array_iterator(array);
	if (iter == NULL)
		return false;

	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		if (prop_object_type(obj) != PROP_TYPE_STRING)
			continue;
		if (prop_string_equals_cstring(obj, val)) {
			prop_object_iterator_release(iter);
			return true;
		}
	}

	prop_object_iterator_release(iter);
	return false;
}

prop_object_iterator_t
xbps_get_array_iter_from_dict(prop_dictionary_t dict, const char *key)
{
	prop_array_t array;

	assert(dict != NULL);
	assert(key != NULL);

	array = prop_dictionary_get(dict, key);
	if (array == NULL || prop_object_type(array) != PROP_TYPE_ARRAY)
		return NULL;

	return prop_array_iterator(array);
}

bool
xbps_remove_pkg_dict_from_file(const char *pkg, const char *plist)
{
	prop_dictionary_t pdict;
	prop_array_t array;
	prop_object_t obj;
	prop_object_iterator_t iter;
	const char *curpkg;
	size_t i = 0;

	assert(pkg != NULL);
	assert(plist != NULL);

	pdict = prop_dictionary_internalize_from_file(plist);
	if (pdict == NULL)
		return false;

	array = prop_dictionary_get(pdict, "packages");
	if (array == NULL || prop_object_type(array) != PROP_TYPE_ARRAY)
		return false;

	iter = prop_array_iterator(array);
	if (iter == NULL)
		return false;

	/* Iterate over the array of dictionaries to find its index. */
	while ((obj = prop_object_iterator_next(iter))) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &curpkg);
		if ((curpkg && (strcmp(curpkg, pkg) == 0))) {
			/* Found, remove it and write plist file. */
			prop_array_remove(array, i);
			prop_object_iterator_release(iter);
			goto wr_plist;
		}
		i++;
	}

	prop_object_iterator_release(iter);
	prop_object_release(pdict);
	errno = ENODEV;
	return false;

wr_plist:
	if (!prop_dictionary_externalize_to_file(pdict, plist)) {
		prop_object_release(pdict);
		return false;
	}

	prop_object_release(pdict);

	return true;
}
