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

static prop_dictionary_t pkg_props;
static bool pkg_props_initialized;

static int
create_pkg_props_dictionary(void)
{
	prop_array_t unsorted, missing;
	int rv = 0;

	if (pkg_props_initialized)
		return 0;

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

	pkg_props_initialized = true;

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
xbps_get_pkg_props(void)
{
	if (pkg_props_initialized == false)
		return NULL;

	return prop_dictionary_copy(pkg_props);
}

int
xbps_prepare_repolist_data(void)
{
	prop_dictionary_t dict = NULL;
	prop_array_t array;
	prop_object_t obj;
	prop_object_iterator_t iter;
	struct repository_data *rdata;
	const char *rootdir;
	char *plist;
	int rv = 0;
	static bool repodata_initialized;

	if (repodata_initialized)
		return 0;

	SIMPLEQ_INIT(&repodata_queue);

	rootdir = xbps_get_rootdir();
	if (rootdir == NULL)
		rootdir = "";

	plist = xbps_xasprintf("%s/%s/%s", rootdir,
	    XBPS_META_PATH, XBPS_REPOLIST);
	if (plist == NULL) {
		rv = EINVAL;
		goto out;
	}

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
                free(plist);
		rv = errno;
		goto out;
	}
	free(plist);

	array = prop_dictionary_get(dict, "repository-list");
	if (array == NULL) {
		rv = EINVAL;
		goto out;
	}

	iter = prop_array_iterator(array);
	if (iter == NULL) {
		rv = ENOMEM;
		goto out;
	}

	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		/*
		 * Iterate over the repository pool and add the dictionary
		 * for current repository into the queue.
		 */
		plist =
		    xbps_get_pkg_index_plist(prop_string_cstring_nocopy(obj));
		if (plist == NULL) {
			rv = EINVAL;
			goto out2;
		}

		rdata = malloc(sizeof(struct repository_data));
		if (rdata == NULL) {
			rv = errno;
			goto out2;
		}

		rdata->rd_repod = prop_dictionary_internalize_from_file(plist);
		if (rdata->rd_repod == NULL) {
			free(plist);
			rv = errno;
			goto out2;
		}
		free(plist);
		SIMPLEQ_INSERT_TAIL(&repodata_queue, rdata, chain);
	}

	repodata_initialized = true;

out2:
	prop_object_iterator_release(iter);
out:
	prop_object_release(dict);
	if (rv != 0)
		xbps_release_repolist_data();

	return rv;

}

void
xbps_release_repolist_data(void)
{
	struct repository_data *rdata;

	while ((rdata = SIMPLEQ_FIRST(&repodata_queue)) != NULL) {
		SIMPLEQ_REMOVE(&repodata_queue, rdata, repository_data, chain);
		prop_object_release(rdata->rd_repod);
		free(rdata);
	}
}

int
xbps_find_new_pkg(const char *pkgname, prop_dictionary_t instpkg)
{
	prop_dictionary_t pkgrd = NULL;
	prop_array_t unsorted;
	struct repository_data *rdata;
	const char *repoloc, *repover, *instver;
	int rv = 0;

	assert(pkgname != NULL);
	assert(instpkg != NULL);

	SIMPLEQ_FOREACH(rdata, &repodata_queue, chain) {
		/*
		 * Get the package dictionary from current repository.
		 * If it's not there, pass to the next repository.
		 */
		pkgrd = xbps_find_pkg_in_dict(rdata->rd_repod,
		    "packages", pkgname);
		if (pkgrd != NULL) {
			/*
			 * Check if installed version is >= than the
			 * one available in current repository.
			 */
			prop_dictionary_get_cstring_nocopy(instpkg,
			    "version", &instver);
			prop_dictionary_get_cstring_nocopy(pkgrd,
			    "version", &repover);
			if (xbps_cmpver(instver, repover) >= 0)
				goto out;

			break;
		}
	}
	if (pkgrd == NULL)
		return 0;

	/*
	 * Create master pkg dictionary.
	 */
	if ((rv = create_pkg_props_dictionary()) != 0)
		goto out;

	/*
	 * Set repository in pkg dictionary.
	 */
	if (!prop_dictionary_get_cstring_nocopy(rdata->rd_repod,
	    "location-local", &repoloc)) {
		rv = EINVAL;
		goto out;
	}
	prop_dictionary_set_cstring(pkgrd, "repository", repoloc);

	/*
	 * Construct the dependency chain for this package.
	 */
	if ((rv = xbps_find_deps_in_pkg(pkg_props, pkgrd)) != 0)
		goto out;

	/*
	 * Add required package dictionary into the packages
	 * dictionary.
	 */
	unsorted = prop_dictionary_get(pkg_props, "unsorted_deps");
	if (unsorted == NULL) {
		rv = EINVAL;
		goto out;
	}

	if (!prop_array_add(unsorted, pkgrd))
		rv = errno;

out:
	if (rv != 0)
		xbps_release_repolist_data();

	return rv;
}

int
xbps_prepare_pkg(const char *pkgname)
{
	prop_dictionary_t pkgrd = NULL;
	prop_array_t pkgs_array;
	struct repository_data *rdata;
	const char *repoloc;
	int rv = 0;

	assert(pkgname != NULL);

	if ((rv = xbps_prepare_repolist_data()) != 0)
		return rv;

	SIMPLEQ_FOREACH(rdata, &repodata_queue, chain) {
		/*
		 * Get the package dictionary from current repository.
		 * If it's not there, pass to the next repository.
		 */
		pkgrd = xbps_find_pkg_in_dict(rdata->rd_repod,
		    "packages", pkgname);
		if (pkgrd != NULL)
			break;
	}
	if (pkgrd == NULL) {
		rv = EAGAIN;
		goto out;
	}

	/*
	 * Create master pkg dictionary.
	 */
	if ((rv = create_pkg_props_dictionary()) != 0)
		goto out;

	/*
	 * Set repository in pkg dictionary.
	 */
	if (!prop_dictionary_get_cstring_nocopy(rdata->rd_repod,
	    "location-local", &repoloc)) {
		rv = EINVAL;
		goto out;
	}
	prop_dictionary_set_cstring(pkgrd, "repository", repoloc);
	prop_dictionary_set_cstring(pkg_props, "origin", pkgname);

	/*
	 * Check if this package needs dependencies.
	 */
	if (xbps_pkg_has_rundeps(pkgrd)) {
		/*
		 * Construct the dependency chain for this package.
		 */
		if ((rv = xbps_find_deps_in_pkg(pkg_props, pkgrd)) != 0)
			goto out;

		/*
		 * Sort the dependency chain for this package.
		 */
		if ((rv = xbps_sort_pkg_deps(pkg_props)) != 0)
			goto out;
	} else {
		/*
		 * Package has no deps, so we have to create the
		 * "packages" array.
		 */
		pkgs_array = prop_array_create();
		if (pkgs_array == NULL) {
			rv = errno;
			goto out;
		}
		if (!prop_dictionary_set(pkg_props, "packages",
		    pkgs_array)) {
			rv = errno;
			goto out;
		}
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

	if (!prop_array_add(pkgs_array, pkgrd))
		rv = errno;

out:
	xbps_release_repolist_data();

	return rv;
}
