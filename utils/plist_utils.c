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

#include "xbps_api.h"

bool
xbps_add_array_to_dict(prop_dictionary_t dict, prop_array_t array,
		       const char *key)
{
	if (dict == NULL || array == NULL || key == NULL)
		return false;

	if (!prop_dictionary_set(dict, key, array))
		return false;

	prop_object_release(array);
	return true;
}

bool
xbps_add_obj_to_array(prop_array_t array, prop_object_t obj)
{
	if (array == NULL || obj == NULL)
		return false;

	if (!prop_array_add(array, obj)) {
		prop_object_release(array);
		return false;
	}

	prop_object_release(obj);
	return true;
}

prop_dictionary_t
xbps_find_pkg_in_dict(prop_dictionary_t dict, const char *key,
		      const char *pkgname)
{
	prop_array_t array;
	prop_object_iterator_t iter;
	prop_object_t obj;
	const char *dpkgn;

	if (dict == NULL || pkgname == NULL || key == NULL)
		return NULL;

	array = prop_dictionary_get(dict, key);
	if (array == NULL || prop_object_type(array) != PROP_TYPE_ARRAY)
		return NULL;

	iter = prop_array_iterator(array);
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

	if (array == NULL || val == NULL)
		return false;

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

bool
xbps_register_repository(const char *uri)
{
	prop_dictionary_t dict;
	prop_array_t array = NULL;
	prop_object_t obj;

	if (uri == NULL)
		return false;

	/* First check if we have the repository plist file. */
	dict = prop_dictionary_internalize_from_file(XBPS_REPOLIST_PATH);
	if (dict == NULL) {
		/* Looks like not, create it. */
		dict = prop_dictionary_create();
		if (dict == NULL)
			return false;

		/* Create the array and add the repository URI on it. */
		array = prop_array_create();
		if (array == NULL) {
			prop_object_release(dict);
			return false;
		}

		if (!prop_array_set_cstring_nocopy(array, 0, uri))
			goto fail;

		/* Add the array obj into the main dictionary. */
		if (!xbps_add_array_to_dict(dict, array, "repository-list"))
			goto fail;

		/* Write dictionary into plist file. */
		if (!prop_dictionary_externalize_to_file(dict,
		    XBPS_REPOLIST_PATH))
			goto fail;

		prop_object_release(array);
	} else {
		/* Append into the array, the plist file exists. */
		array = prop_dictionary_get(dict, "repository-list");
		if (array == NULL || prop_object_type(array) != PROP_TYPE_ARRAY)
			return false;

		/* It seems that this object is already there */
		if (xbps_find_string_in_array(array, uri)) {
			errno = EEXIST;
			return false;
		}

		obj = prop_string_create_cstring(uri);
		if (!xbps_add_obj_to_array(array, obj)) {
			prop_object_release(obj);
			return false;
		}

		/* Write dictionary into plist file. */
		if (!prop_dictionary_externalize_to_file(dict,
		    XBPS_REPOLIST_PATH)) {
			prop_object_release(obj);
			return false;
		}

		prop_object_release(obj);
	}

	return true;

fail:
	if (array)
		prop_object_release(array);
	if (dict)
		prop_object_release(dict);
	return false;
}

void
xbps_list_pkgs_in_dict(prop_dictionary_t dict, const char *key)
{
	prop_array_t array;
	prop_object_t obj;
	prop_object_iterator_t iter;
	const char *pkgname, *version, *short_desc;

	if (dict == NULL || key == NULL) {
		printf("%s: NULL dict/key\n", __func__);
		exit(1);
	}

	array = prop_dictionary_get(dict, key);
	if (array == NULL || prop_object_type(array) != PROP_TYPE_ARRAY) {
		printf("%s: NULL or incorrect array type\n", __func__);
		exit(1);
	}

	iter = prop_array_iterator(array);
	if (iter == NULL) {
		printf("%s: NULL iter\n", __func__);
		exit(1);
	}

	while ((obj = prop_object_iterator_next(iter))) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
		prop_dictionary_get_cstring_nocopy(obj, "version", &version);
		prop_dictionary_get_cstring_nocopy(obj, "short_desc",
		    &short_desc);
		if (pkgname && version && short_desc)
			printf("%s (%s)\t%s\n", pkgname, version, short_desc);
	}

	prop_object_iterator_release(iter);
}
