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

struct binpkg_instargs {
	const char *pkgname;
	bool update;
};

static int	install_binpkg_repo_cb(prop_object_t, void *, bool *);

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

	rv = xbps_unpack_binary_pkg(repo, pkgrd, update);
	if (rv == 0) {
		rv = xbps_register_pkg(pkgrd, update, automatic);
		if (rv != 0) {
			printf("ERROR: couldn't register %s-%s! (%s)\n",
			    pkgname, version, strerror(rv));
			return rv;
		}
	}

	return 0;
}

int
xbps_install_binary_pkg(const char *pkgname, bool update)
{
	struct binpkg_instargs bi;
	int rv = 0;

	assert(pkgname != NULL);

	bi.pkgname = pkgname;
	bi.update = update;
	/*
	 * Iterate over the repository pool and find out if we have
	 * all available binary packages.
	 */
	rv = xbps_callback_array_iter_in_repolist(install_binpkg_repo_cb,
	    (void *)&bi);
	if (rv == 0 && errno != 0)
		return errno;

	return rv;
}

static int
install_binpkg_repo_cb(prop_object_t obj, void *arg, bool *cbloop_done)
{
	prop_dictionary_t repod, pkgrd;
	struct binpkg_instargs *bi = arg;
	size_t len = 0;
	const char *repoloc, *instver;
	char *plist, *pkg;
	int rv = 0;

	plist = xbps_get_pkg_index_plist(prop_string_cstring_nocopy(obj));
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
	pkgrd = xbps_find_pkg_in_dict(repod, "packages", bi->pkgname);
	if (pkgrd == NULL) {
		prop_object_release(repod);
		errno = EAGAIN;
		return 0;
	}

	/*
	 * Check if available version in repository is already installed,
	 * and return immediately in that case.
	 */
	prop_dictionary_get_cstring_nocopy(pkgrd, "version", &instver);
	len = strlen(bi->pkgname) + strlen(instver) + 2;
	pkg = malloc(len);
	if (pkg == NULL) {
		rv = EINVAL;
		goto out;
	}
	(void)snprintf(pkg, len, "%s-%s", bi->pkgname, instver);
	if (xbps_check_is_installed_pkg(pkg) == 0) {
		free(pkg);
		rv = EEXIST;
		goto out;
	}
	free(pkg);

	/*
	 * Check SHA256 hash for binary package before anything else.
	 */
	if (!prop_dictionary_get_cstring_nocopy(repod, "location-local",
	    &repoloc)) {
		prop_object_release(repod);
		return EINVAL;
	}

	if ((rv = xbps_check_pkg_file_hash(pkgrd, repoloc)) != 0)
		goto out;

	/*
	 * Check if this package needs dependencies.
	 */
	if (!xbps_pkg_has_rundeps(pkgrd)) {
		/* pkg has no deps, just install it. */
		goto install;
	}

	/*
	 * Construct the dependency chain for this package.
	 */
	if ((rv = xbps_find_deps_in_pkg(pkgrd)) != 0) {
		prop_object_release(repod);
		if (rv == ENOENT) {
			errno = ENOENT;
			return 0;
		}
		return rv;
	}

	/*
	 * Install all required dependencies and the package itself.
	 */
	rv = xbps_install_pkg_deps(bi->pkgname, bi->update);
	if (rv != 0)
		goto out;

install:
	rv = xbps_install_binary_pkg_fini(repod, pkgrd, bi->update);
	if (rv == 0) {
		*cbloop_done = true;
		/* Cleanup errno, just in case */
		errno = 0;
	}

out:
	prop_object_release(repod);

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
	const char *pkgname, *version, *desc;
	char *plist;
	int rv = 0;

	plist = xbps_append_full_path(true, NULL, XBPS_REGPKGDB);
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

		if (update && pkgrd && xbps_pkg_has_rundeps(pkgrd)) {
			/*
			 * If updating a package, update the requiredby
			 * objects and set new version in pkg dictionary.
			 */
			rv = xbps_requiredby_pkg_add(array, pkgrd, true);
			if (rv != 0) {
				prop_object_release(newpkgd);
				goto out;
			}
			prop_dictionary_set_cstring_nocopy(pkgd,
			    "version", version);

		} else {
			/*
			 * If installing a package, update the requiredby
			 * objects and add new pkg dictionary into the
			 * packages array.
			 */
			if (pkgrd && xbps_pkg_has_rundeps(pkgrd)) {
				rv = xbps_requiredby_pkg_add(array, pkgrd,
				     false);
				if (rv != 0) {
					prop_object_release(newpkgd);
					goto out;
				}
			}
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
