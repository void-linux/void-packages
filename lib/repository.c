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
#include <limits.h>
#include <prop/proplib.h>

#include <xbps_api.h>

struct callback_args {
	const char *string;
	ssize_t number;
};

int
xbps_remove_string_from_array(prop_object_t obj, void *arg, bool *loop_done)
{
	static ssize_t idx;
	struct callback_args *cb = arg;

	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	if (prop_string_equals_cstring(obj, cb->string)) {
		cb->number = idx;
		*loop_done = true;
		return 0;
	}
	idx++;

	return 0;
}

bool
xbps_register_repository(const char *uri)
{
	prop_dictionary_t dict;
	prop_array_t array = NULL;
	prop_object_t obj;
	char *plist;

	assert(uri != NULL);

	plist = xbps_append_full_path(true, NULL, XBPS_REPOLIST);
	if (plist == NULL) {
		errno = EINVAL;
		return false;
	}

	/* First check if we have the repository plist file. */
	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		/* Looks like not, create it. */
		dict = prop_dictionary_create();
		if (dict == NULL) {
			free(plist);
			return false;
		}

		/* Create the array and add the repository URI on it. */
		array = prop_array_create();
		if (array == NULL) {
			prop_object_release(dict);
			free(plist);
			return false;
		}

		if (!prop_array_set_cstring_nocopy(array, 0, uri))
			goto fail;

		/* Add the array obj into the main dictionary. */
		if (!xbps_add_obj_to_dict(dict, array, "repository-list"))
			goto fail;

		/* Write dictionary into plist file. */
		if (!prop_dictionary_externalize_to_file(dict, plist))
			goto fail;

		prop_object_release(dict);

	} else {
		/* Append into the array, the plist file exists. */
		array = prop_dictionary_get(dict, "repository-list");
		if (array == NULL)
			goto fail;

		assert(prop_object_type(array) == PROP_TYPE_ARRAY);

		/* It seems that this object is already there */
		if (xbps_find_string_in_array(array, uri)) {
			errno = EEXIST;
			goto fail;
		}

		obj = prop_string_create_cstring(uri);
		if (!xbps_add_obj_to_array(array, obj)) {
			prop_object_release(obj);
			return false;
		}

		/* Write dictionary into plist file. */
		if (!prop_dictionary_externalize_to_file(dict, plist)) {
			prop_object_release(obj);
			return false;
		}

		prop_object_release(dict);
	}

	free(plist);

	return true;

fail:
	prop_object_release(dict);
	free(plist);

	return false;
}

bool
xbps_unregister_repository(const char *uri)
{
	prop_dictionary_t dict;
	prop_array_t array;
	struct callback_args *cb;
	char *plist;
	bool done = false;

	assert(uri != NULL);

	plist = xbps_append_full_path(true, NULL, XBPS_REPOLIST);
	if (plist == NULL) {
		errno = EINVAL;
		return false;
	}

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		free(plist);
		return false;
	}

	array = prop_dictionary_get(dict, "repository-list");
	if (array == NULL) {
		prop_object_release(dict);
		free(plist);
		return false;
	}

	assert(prop_object_type(array) == PROP_TYPE_ARRAY);

	cb = malloc(sizeof(*cb));
	if (cb == NULL) {
		prop_object_release(dict);
		free(plist);
		errno = ENOMEM;
		return false;
	}

	cb->string = uri;
	cb->number = -1;

	done = xbps_callback_array_iter_in_dict(dict, "repository-list",
		    xbps_remove_string_from_array, cb);
	if (done == 0 && cb->number >= 0) {
		/* Found, remove it. */
		prop_array_remove(array, cb->number);

		/* Update plist file. */
		if (prop_dictionary_externalize_to_file(dict, plist)) {
			prop_object_release(dict);
			free(cb);
			free(plist);
			return true;
		}
	} else {
		/* Not found. */
		errno = ENOENT;
	}

	prop_object_release(dict);
	free(cb);
	free(plist);

	return false;
}
