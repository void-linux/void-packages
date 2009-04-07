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
xbps_install_binary_pkg_fini(prop_dictionary_t repo, prop_dictionary_t pkgrd,
			     bool update)
{
	prop_dictionary_t instpkg;
	const char *pkgname, *version, *instver;
	int rv = 0;
	bool automatic = false;

	assert(pkg != NULL);
	prop_dictionary_get_cstring_nocopy(pkgrd, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(pkgrd, "version", &version);

	if (repo == false)
		automatic = true;

	if (update == true) {
		/*
		 * Update a package, firstly removing current package.
		 */
		instpkg = xbps_find_pkg_installed_from_plist(pkgname);
		if (instpkg == NULL)
			return EINVAL;

		prop_dictionary_get_cstring_nocopy(instpkg, "version",
		    &instver);
		printf("Removing current package %s-%s ...\n", pkgname,
		    instver);
		prop_object_release(instpkg);
		rv = xbps_remove_binary_pkg(pkgname, update);
		if (rv != 0)
			return rv;
		printf("Installing new package %s-%s ...\n", pkgname, version);
	} else {
		printf("Installing %s%s: found version %s ...\n",
		    automatic ? "dependency " : "", pkgname, version);
	}
	(void)fflush(stdout);

	rv = xbps_unpack_binary_pkg(repo, pkgrd);
	if (rv == 0) {
		rv = xbps_register_pkg(pkgrd, update, automatic);
		if (rv != 0) {
			printf("ERROR: couldn't register %s-%s! (%s)\n",
			    pkgname, version, strerror(rv));
			return rv;
		}
	}

	return rv;
}

int
xbps_install_binary_pkg(const char *pkgname, bool update)
{
	prop_dictionary_t repod = NULL, repolistd, pkgrd = NULL;
	prop_array_t array;
	prop_object_t obj;
	prop_object_iterator_t repolist_iter;
	const char *repoloc, *instver, *rootdir;
	char *plist, *pkg;
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
	plist = NULL;

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
	 * Check if available version in repository is already
	 * installed, and return immediately in that case.
	 */
	prop_dictionary_get_cstring_nocopy(pkgrd, "version", &instver);
	pkg = xbps_xasprintf("%s-%s", pkgname, instver);
	if (pkg == NULL) {
		rv = errno;
		goto out;
	}
	if (xbps_check_is_installed_pkg(pkg) == 0) {
		free(pkg);
		rv = EEXIST;
		goto out;
	}
	free(pkg);

	/*
	 * Check SHA256 hash for binary package before anything else.
	 */
	if (!prop_dictionary_get_cstring_nocopy(repod,
	    "location-local", &repoloc)) {
		rv = EINVAL;
		goto out;
	}

	if ((rv = xbps_check_pkg_file_hash(pkgrd, repoloc)) != 0)
		goto out;

	/*
	 * Check if this package needs dependencies.
	 */
	if (xbps_pkg_has_rundeps(pkgrd)) {
		/*
		 * Construct the dependency chain for this package.
		 */
		printf("Finding required dependencies...\n");
		if ((rv = xbps_find_deps_in_pkg(pkgrd, repolist_iter)) != 0)
			goto out;

		/*
		 * Install all required dependencies and the package itself.
		 */
		rv = xbps_install_pkg_deps(pkgname, update);
		if (rv != 0)
			goto out;
	}

	/*
	 * Finally install the binary package that was requested by
	 * the client.
	 */
	rv = xbps_install_binary_pkg_fini(repod, pkgrd, update);
out:
	prop_object_release(repod);
out2:
	prop_object_iterator_release(repolist_iter);
	prop_object_release(repolistd);

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
xbps_register_pkg(prop_dictionary_t pkgrd, bool update, bool automatic)
{
	prop_dictionary_t dict, pkgd, newpkgd;
	prop_array_t array;
	const char *pkgname, *version, *desc, *rootdir;
	char *plist;
	int rv = 0;

	rootdir = xbps_get_rootdir();
	plist = xbps_xasprintf("%s/%s/%s", rootdir,
	    XBPS_META_PATH, XBPS_REGPKGDB);
	if (plist == NULL)
		return EINVAL;

	prop_dictionary_get_cstring_nocopy(pkgrd, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(pkgrd, "version", &version);
	prop_dictionary_get_cstring_nocopy(pkgrd, "short_desc", &desc);

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		/*
		 * No packages registered yet. Register package into
		 * the dictionary.
		 */
		dict = prop_dictionary_create();
		if (dict == NULL) {
			free(plist);
			return ENOMEM;
		}

		array = prop_array_create();
		if (array == NULL) {
			rv = ENOMEM;
			goto out;
		}

		pkgd = make_dict_from_pkg(pkgname, version, desc);
		if (!xbps_add_obj_to_array(array, pkgd)) {
			prop_object_release(array);
			rv = EINVAL;
			goto out;
		}

		prop_dictionary_set_bool(pkgd, "automatic-install",
			automatic);

		if (!xbps_add_obj_to_dict(dict, array, "packages")) {
			prop_object_release(array);
			rv = EINVAL;
			goto out;
		}

	} else {
		/*
		 * Check if package is already registered and return
		 * an error if not updating.
		 */
		pkgd = xbps_find_pkg_in_dict(dict, "packages", pkgname);
		if (pkgd != NULL && update == false) {
			rv = EEXIST;
			goto out;
		}
		array = prop_dictionary_get(dict, "packages");
		if (array == NULL) {
			rv = ENOENT;
			goto out;
		}

		newpkgd = make_dict_from_pkg(pkgname, version, desc);
		prop_dictionary_set_bool(newpkgd, "automatic-install",
		    automatic);

		/*
		 * Add the requiredby objects for dependent packages.
		 */
		if (pkgrd && xbps_pkg_has_rundeps(pkgrd)) {
			rv = xbps_requiredby_pkg_add(array, pkgrd);
			if (rv != 0) {
				prop_object_release(newpkgd);
				goto out;
			}
		}

		if (update) {
			/*
			 * If updating a package, set new version in
			 * pkg dictionary.
			 */
			prop_dictionary_set_cstring_nocopy(pkgd,
			    "version", version);
		} else {
			/*
			 * If installing a package, add new pkg
			 * dictionary into the packages array.
			 */
			if (!xbps_add_obj_to_array(array, newpkgd)) {
				prop_object_release(newpkgd);
				rv = EINVAL;
				goto out;
			}
		}
	}

	if (!prop_dictionary_externalize_to_file(dict, plist))
		rv = errno;

out:
	prop_object_release(dict);
	free(plist);

	return rv;
}
