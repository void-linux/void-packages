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

#include <xbps_api.h>

static int
add_pkg_into_requiredby(prop_dictionary_t pkgd, const char *reqname)
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

int
xbps_update_pkg_requiredby(prop_array_t regar, prop_dictionary_t pkg)
{
	prop_array_t rdeps;
	prop_object_t obj, obj2;
	prop_object_iterator_t iter, iter2;
	size_t len = 0;
	const char *reqname, *pkgname, *version;
	char *rdepname, *fpkgn;
	int rv = 0;

	prop_dictionary_get_cstring_nocopy(pkg, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(pkg, "version", &version);
	len = strlen(pkgname) + strlen(version) + 2;
	fpkgn = malloc(len);
	if (fpkgn == NULL)
		return ENOMEM;

	(void)snprintf(fpkgn, len, "%s-%s", pkgname, version);

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
			free(fpkgn);
			free(rdepname);
			prop_object_iterator_release(iter);
			return ENOMEM;
		}

		/*
		 * Iterate over the array to find the dictionary for the
		 * current run dependency.
		 */
		while ((obj2 = prop_object_iterator_next(iter2)) != NULL) {
			prop_dictionary_get_cstring_nocopy(obj2, "pkgname",
			    &reqname);
			if (strcmp(rdepname, reqname) == 0) {
				rv = add_pkg_into_requiredby(obj2, fpkgn);
				if (rv != 0) {
					free(rdepname);
					prop_object_iterator_release(iter2);
					goto out;
				}
				break;
			}
		}
		free(rdepname);
		prop_object_iterator_release(iter2);
	}

out:
	free(fpkgn);
	prop_object_iterator_release(iter);

	return rv;
}
