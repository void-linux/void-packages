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
#include <unistd.h>
#include <fcntl.h>

#include <xbps_api.h>

int
xbps_install_binary_pkg_fini(prop_dictionary_t repo, prop_dictionary_t pkg,
			     const char *destdir)
{
	const char *pkgname, *version, *desc;
	int rv = 0;

	assert(pkg != NULL);
	prop_dictionary_get_cstring_nocopy(pkg, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(pkg, "version", &version);
	prop_dictionary_get_cstring_nocopy(pkg, "short_desc", &desc);
	assert(pkgname != NULL);
	assert(version != NULL);
	assert(desc != NULL);

	rv = xbps_unpack_binary_pkg(repo, pkg, destdir, NULL);
	if (rv == 0) {
		rv = xbps_register_pkg(pkgname, version, desc);
		if (rv == EEXIST)
			rv = 0;
	}

	return rv;
}

int
xbps_install_binary_pkg(const char *pkgname, const char *destdir)
{
	prop_array_t array;
	prop_dictionary_t repolistd, repod, pkgrd = NULL;
	prop_object_t obj;
	prop_object_iterator_t iter;
	char *plist;
	int rv = 0;

	assert(pkgname != NULL);
	if (destdir) {
		if ((rv = chdir(destdir)) != 0)
			return errno;
	} else
		destdir = "NOTSET";

	/*
	 * Get the dictionary with the list of registered repositories.
	 */
	plist = xbps_append_full_path(true, NULL, XBPS_REPOLIST);
	if (plist == NULL)
		return EINVAL;

	repolistd = prop_dictionary_internalize_from_file(plist);
	if (repolistd == NULL) {
		free(plist);
		return EINVAL;
	}
	free(plist);

	/*
	 * Iterate over the repository pool and find out if we have
	 * all available binary packages.
	 */
        array = prop_dictionary_get(repolistd, "repository-list");
        assert(array != NULL);

        iter = prop_array_iterator(array);
        if (iter == NULL) {
                prop_object_release(repolistd);
                return ENOMEM;
        }

	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		plist = xbps_append_full_path(false,
		    prop_string_cstring_nocopy(obj), XBPS_PKGINDEX);
		if (plist == NULL) {
			rv = EINVAL;
			goto out;
		}

		repod = prop_dictionary_internalize_from_file(plist);
		if (repod == NULL) {
			free(plist);
			rv = errno;
			goto out;
		}
		free(plist);

		/*
		 * Get the package dictionary from current repository.
		 * If it's not there, pass to the next repository.
		 */
		pkgrd = xbps_find_pkg_in_dict(repod, "packages", pkgname);
		if (pkgrd == NULL) {
			prop_object_release(repod);
			rv = XBPS_PKG_ENOTINREPO;
			continue;
		}

		/*
		 * Check if this package needs dependencies.
		 */
		if (!xbps_pkg_has_rundeps(pkgrd)) {
			/* pkg has no deps, just install it. */
			rv = xbps_install_binary_pkg_fini(repod, pkgrd,
			    destdir);
			prop_object_release(repod);
			goto out;
		}

		/*
		 * Construct the dependency chain for this package. If any
		 * dependency is not available, pass to the next repository.
		 */
		rv = xbps_find_deps_in_pkg(repod, pkgrd);
		if (rv != 0) {
			prop_object_release(repod);
			if (rv == XBPS_PKG_ENOTINREPO)
				continue;

			goto out;
                }

		/*
		 * Install all required dependencies and the package itself.
		 */
		rv = xbps_install_pkg_deps(pkgrd, destdir);
		if (rv == 0) {
			rv = xbps_install_binary_pkg_fini(repod, pkgrd,
			    destdir);
		}
                prop_object_release(repod);
		break;
        }

out:
	prop_object_release(repolistd);
        prop_object_iterator_release(iter);

	return rv;
}

static prop_dictionary_t
make_dict_from_pkg(const char *name, const char *ver, const char *desc)
{
	prop_dictionary_t dict;

	dict = prop_dictionary_create();
	assert(dict != NULL);

	prop_dictionary_set_cstring_nocopy(dict, "pkgname", name);
	prop_dictionary_set_cstring_nocopy(dict, "version", ver);
	prop_dictionary_set_cstring_nocopy(dict, "short_desc", desc);

	return dict;
}

int
xbps_register_pkg(const char *pkgname, const char *version, const char *desc)
{
	prop_dictionary_t dict, pkgd;
	prop_array_t array;
	char *plist;
	int rv = 0;

	assert(pkgname != NULL);
	assert(version != NULL);
	assert(desc != NULL);

	plist = xbps_append_full_path(true, NULL, XBPS_REGPKGDB);
	if (plist == NULL)
		return EINVAL;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		/* No packages registered yet. */
		dict = prop_dictionary_create();
		if (dict == NULL) {
			free(plist);
			return ENOMEM;
		}

		array = prop_array_create();
		if (array == NULL) {
			free(plist);
			prop_object_release(dict);
			return ENOMEM;
		}

		pkgd = make_dict_from_pkg(pkgname, version, desc);

		if (!xbps_add_obj_to_array(array, pkgd)) {
			prop_object_release(array);
			prop_object_release(dict);
			prop_object_release(pkgd);
			free(plist);
			return EINVAL;
		}

		if (!xbps_add_obj_to_dict(dict, array, "packages")) {
			prop_object_release(array);
			prop_object_release(dict);
			free(plist);
			return EINVAL;
		}

	} else {
		/* Check if package is already registered. */
		pkgd = xbps_find_pkg_in_dict(dict, "packages", pkgname);
		if (pkgd != NULL) {
			prop_object_release(dict);
			free(plist);
			return EEXIST;
		}

		pkgd = make_dict_from_pkg(pkgname, version, desc);
		array = prop_dictionary_get(dict, "packages");
		assert(array != NULL);

		if (!xbps_add_obj_to_array(array, pkgd)) {
			prop_object_release(pkgd);
			prop_object_release(dict);
			free(plist);
			return EINVAL;
		}
	}

	if (!prop_dictionary_externalize_to_file(dict, plist))
		rv = errno;

	prop_object_release(dict);
	free(plist);

	return rv;
}
