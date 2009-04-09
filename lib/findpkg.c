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

static int	create_pkg_props_dictionary(const char *);

static prop_dictionary_t pkg_props;

static int
create_pkg_props_dictionary(const char *pkgname)
{
	prop_array_t unsorted, missing;
	int rv = 0;

	assert(pkgname != NULL);

	pkg_props = prop_dictionary_create();
	if (pkg_props == NULL)
		return ENOMEM;

	missing = prop_array_create();
	if (missing == NULL) {
		rv = ENOMEM;
		goto fail;
	}

        unsorted = prop_array_create();
        if (unsorted == NULL) {
                rv = ENOMEM;
                goto fail2;
        }

        if (!xbps_add_obj_to_dict(pkg_props, missing, "missing_deps")) {
                rv = EINVAL;
                goto fail3;
        }
        if (!xbps_add_obj_to_dict(pkg_props, unsorted, "unsorted_deps")) {
                rv = EINVAL;
                goto fail3;
        }

	prop_dictionary_set_cstring_nocopy(pkg_props, "origin", pkgname);

        return rv;

fail3:
        prop_object_release(unsorted);
fail2:
        prop_object_release(missing);
fail:
        prop_object_release(pkg_props);

        return rv;
}

prop_dictionary_t
xbps_get_pkg_props(const char *pkgname)
{
	prop_string_t origin;

	if (pkg_props == NULL || prop_dictionary_count(pkg_props) == 0)
		return NULL;

	origin = prop_dictionary_get(pkg_props, "origin");
	if (!prop_string_equals_cstring(origin, pkgname))
		return NULL;

	return prop_dictionary_copy(pkg_props);
}

int
xbps_prepare_pkg(const char *pkgname)
{
	prop_dictionary_t repod = NULL, repolistd, pkgrd = NULL;
	prop_array_t array, pkgs_array;
	prop_object_t obj;
	prop_object_iterator_t repolist_iter;
	const char *repoloc, *rootdir;
	char *plist;
	int rv = 0;

	assert(pkgname != NULL);

	rootdir = xbps_get_rootdir();
	if (rootdir == NULL)
		rootdir = "";

	plist = xbps_xasprintf("%s/%s/%s", rootdir,
	    XBPS_META_PATH, XBPS_REPOLIST);
	if (plist == NULL)
		return EINVAL;

	repolistd = prop_dictionary_internalize_from_file(plist);
	if (repolistd == NULL) {
                free(plist);
		return EINVAL;
	}
	free(plist);

	array = prop_dictionary_get(repolistd, "repository-list");
	if (array == NULL) {
		prop_object_release(repolistd);
		return EINVAL;
	}

	repolist_iter = prop_array_iterator(array);
	if (repolist_iter == NULL) {
		prop_object_release(repolistd);
		return ENOMEM;
	}

        while ((obj = prop_object_iterator_next(repolist_iter)) != NULL) {
		/*
		 * Iterate over the repository pool and find out if we have
		 * the binary package.
		 */
		plist =
		    xbps_get_pkg_index_plist(prop_string_cstring_nocopy(obj));
		if (plist == NULL)
			return EINVAL;

		repod = prop_dictionary_internalize_from_file(plist);
		if (repod == NULL) {
			free(plist);
			return errno;
		}
		free(plist);

		/*
		 * Get the package dictionary from current repository.
		 * If it's not there, pass to the next repository.
		 */
		pkgrd = xbps_find_pkg_in_dict(repod, "packages", pkgname);
		if (pkgrd == NULL) {
			prop_object_release(repod);
			continue;
		}
		break;
	}
	prop_object_iterator_reset(repolist_iter);

	if (pkgrd == NULL) {
		rv = EAGAIN;
		goto out2;
	}

	/*
	 * Create master pkg dictionary.
	 */
	if ((rv = create_pkg_props_dictionary(pkgname)) != 0)
		goto out;

	/*
	 * Set repository in pkg dictionary.
	 */
	if (!prop_dictionary_get_cstring_nocopy(repod,
	    "location-local", &repoloc)) {
		rv = EINVAL;
		goto out;
	}
	prop_dictionary_set_cstring(pkgrd, "repository", repoloc);

	/*
	 * Check if this package needs dependencies.
	 */
	if (xbps_pkg_has_rundeps(pkgrd)) {
		/*
		 * Construct the dependency chain for this package.
		 */
		if ((rv = xbps_find_deps_in_pkg(pkg_props, pkgrd,
		     repolist_iter)) != 0)
			goto out;

		/*
		 * Sort the dependency chain for this package.
		 */
		if ((rv = xbps_sort_pkg_deps(pkg_props)) != 0)
			goto out;
	}

	/*
	 * Add required package dictionary into the packages
	 * dictionary.
	 */
	pkgs_array = prop_dictionary_get(pkg_props, "packages");
	if (pkgs_array == NULL ||
	    prop_object_type(pkgs_array) != PROP_TYPE_ARRAY) {
		rv = EINVAL;
		goto out;
	}

	if (!prop_array_add(pkgs_array, pkgrd)) {
		rv = errno;
		goto out;
	}

	prop_dictionary_remove(pkg_props, "unsorted_deps");

out:
	prop_object_release(repod);
out2:
	prop_object_iterator_release(repolist_iter);
	prop_object_release(repolistd);

	return rv;
}
