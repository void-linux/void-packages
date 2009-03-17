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

#include <xbps_api.h>

static int	add_missing_reqdep(const char *, const char *);
static int	remove_missing_reqdep(const char *);
static int	find_pkg_deps_from_repo(prop_dictionary_t, prop_dictionary_t,
					prop_array_t);
static int 	find_pkg_missing_deps_from_repo(prop_dictionary_t,
						prop_dictionary_t);

static prop_dictionary_t chaindeps;
static bool deps_dict;

/*
 * Creates the dictionary to store the dependency chain.
 */
static int
create_deps_dictionary(void)
{
	prop_array_t unsorted, missing;
	int rv = 0;

	chaindeps = prop_dictionary_create();
	if (chaindeps == NULL)
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

	if (!xbps_add_obj_to_dict(chaindeps, missing, "missing_deps")) {
		rv = EINVAL;
		goto fail3;
	}
	if (!xbps_add_obj_to_dict(chaindeps, unsorted, "unsorted_deps")) {
		rv = EINVAL;
		goto fail3;
	}
	return rv;

fail3:
	prop_object_release(unsorted);
fail2:
	prop_object_release(missing);
fail:
	prop_object_release(chaindeps);

	return rv;
}

static int
store_dependency(prop_dictionary_t origind, prop_dictionary_t depd,
		 prop_dictionary_t repod)
{
	prop_dictionary_t dict, curdict;
	prop_array_t array, rundeps_array, reqby_array;
	prop_string_t reqbystr;
	uint32_t prio = 0;
	size_t len = 0, dirdepscnt = 0, indirdepscnt = 0;
	const char *pkgname, *version, *reqbyname, *reqbyver, *arch;
	const char  *repoloc, *binfile, *originpkg, *short_desc;
	const char *sha256;
	char *reqby, *pkgnver;
	int rv = 0;
	bool indirectdep = false;

	assert(origind != NULL);
	assert(depd != NULL);
	assert(repod != NULL);

	/*
	 * Get some info about dependencies and current repository.
	 */
	prop_dictionary_get_cstring_nocopy(depd, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(depd, "version", &version);
	prop_dictionary_get_cstring_nocopy(depd, "filename", &binfile);
	prop_dictionary_get_cstring_nocopy(depd, "short_desc", &short_desc);
	prop_dictionary_get_cstring_nocopy(depd, "architecture", &arch);
	prop_dictionary_get_cstring_nocopy(depd, "filename-sha256", &sha256);
	prop_dictionary_get_uint32(depd, "priority", &prio);
	prop_dictionary_get_cstring_nocopy(origind, "pkgname", &reqbyname);
	prop_dictionary_get_cstring_nocopy(origind, "version", &reqbyver);
	prop_dictionary_get_cstring_nocopy(repod, "location-local", &repoloc);

	len = strlen(reqbyname) + strlen(reqbyver) + 2;
	reqby = malloc(len + 1);
	if (reqby == NULL)
		return ENOMEM;

	(void)snprintf(reqby, len, "%s-%s", reqbyname, reqbyver);
	reqbystr = prop_string_create_cstring(reqby);

	len = strlen(pkgname) + strlen(version) + 2;
	pkgnver = malloc(len + 1);
	if (pkgnver == NULL) {
		free(reqby);
		return ENOMEM;
	}
	(void)snprintf(pkgnver, len, "%s-%s", pkgname, version);

	/*
	 * Required dependency is not installed. Check if it's
	 * already registered in the chain, and update some objects
	 * or add the object into array otherwise.
	 */
	prop_dictionary_get_cstring_nocopy(chaindeps, "origin", &originpkg);
	curdict = xbps_find_pkg_in_dict(chaindeps, "unsorted_deps", pkgname);
	/*
	 * Update priority and required_by objects.
	 */
	if (curdict) {
		prop_dictionary_get_uint32(curdict, "priority", &prio);
		prop_dictionary_set_uint32(curdict, "priority", ++prio);
		reqby_array = prop_dictionary_get(curdict, "required_by");
		if (!xbps_find_string_in_array(reqby_array, reqby))
			prop_array_add(reqby_array, reqbystr);
		goto out;
	}
	if (strcmp(originpkg, reqbyname)) {
		indirectdep = true;
		prop_dictionary_get_uint32(chaindeps, "indirectdeps_count",
		    &indirdepscnt);
		prop_dictionary_set_uint32(chaindeps, "indirectdeps_count",
		    ++indirdepscnt);
	} else {
		prop_dictionary_get_uint32(chaindeps, "directdeps_count",
		    &dirdepscnt);
		prop_dictionary_set_uint32(chaindeps, "directdeps_count",
		    ++dirdepscnt);
	}

	/*
	 * Create package dep's dictionary and array.
	 */
	dict = prop_dictionary_create();
	if (dict == NULL) {
		rv = ENOMEM;
		goto out;
	}

	array = prop_dictionary_get(chaindeps, "unsorted_deps");
	if (array == NULL) {
		prop_object_release(dict);
		rv = ENOENT;
		goto out;
	}

	/*
	 * Add required objects into package dep's dictionary.
	 */
	prop_dictionary_set_cstring(dict, "pkgname", pkgname);
	prop_dictionary_set_cstring(dict, "version", version);
	rundeps_array = prop_dictionary_get(depd, "run_depends");
	if (rundeps_array && prop_array_count(rundeps_array) > 0)
		prop_dictionary_set(dict, "run_depends", rundeps_array);

	reqby_array = prop_array_create();
	if (reqby_array == NULL) {
		prop_object_release(dict);
		rv = ENOMEM;
		goto out;
	}
	prop_array_add(reqby_array, reqbystr);
	prop_dictionary_set(dict, "required_by", reqby_array);
	prop_dictionary_set_cstring(dict, "repository", repoloc);
	prop_dictionary_set_cstring(dict, "filename", binfile);
	prop_dictionary_set_uint32(dict, "priority", prio);
	prop_dictionary_set_cstring(dict, "short_desc", short_desc);
	prop_dictionary_set_bool(dict, "indirect_dep", indirectdep);
	prop_dictionary_set_cstring(dict, "architecture", arch);
	prop_dictionary_set_cstring(dict, "filename-sha256", sha256);

	/*
	 * Add the dictionary into the array.
	 */
	if (!xbps_add_obj_to_array(array, dict)) {
		prop_object_release(dict);
		rv = EINVAL;
	}

out:
	free(reqby);
	free(pkgnver);
	prop_object_release(reqbystr);

	return rv;
}

static int
add_missing_reqdep(const char *pkgname, const char *version)
{
	prop_array_t array;
	prop_dictionary_t depd;

	assert(pkgname != NULL);
	assert(version != NULL);

	/*
	 * Adds a package into the missing deps array.
	 */
	if (xbps_find_pkg_in_dict(chaindeps, "missing_deps", pkgname))
		return EEXIST;

	array = prop_dictionary_get(chaindeps, "missing_deps");
	depd = prop_dictionary_create();
	if (depd == NULL)
		return ENOMEM;

	prop_dictionary_set_cstring(depd, "pkgname", pkgname);
	prop_dictionary_set_cstring(depd, "version", version);
	if (!xbps_add_obj_to_array(array, depd)) {
		prop_object_release(depd);
		return EINVAL;
	}

	return 0;
}

static int
remove_missing_reqdep(const char *pkgname)
{
	prop_array_t array;
	prop_object_t obj;
	prop_object_iterator_t iter;
	size_t idx = 0;
	const char *curname;
	bool found = false;

	array = prop_dictionary_get(chaindeps, "missing_deps");
	assert(pkgname != NULL);
	assert(version != NULL);
	assert(array != NULL);
	iter = prop_array_iterator(array);
	if (iter == NULL)
		return ENOMEM;
	/*
	 * Finds the index of a package in the missing deps array.
	 */
	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &curname);
		if (strcmp(pkgname, curname) == 0) {
			found = true;
			break;
		}
		idx++;
	}
	prop_object_iterator_release(iter);
	if (found) {
		prop_array_remove(array, idx);
		return 0;
	}

	return ENOENT;
}

int
xbps_find_deps_in_pkg(prop_dictionary_t pkg)
{
	prop_array_t array, pkg_rdeps, missing_rdeps;
	prop_dictionary_t repolistd, repod;
	prop_object_t obj;
	prop_object_iterator_t iter;
	char *plist;
	int rv = 0;

	assert(pkg != NULL);

	pkg_rdeps = prop_dictionary_get(pkg, "run_depends");
	if (pkg_rdeps == NULL)
		return 0;

	/*
	 * Get the dictionary with the list of registered repositories.
	 */
	plist = xbps_append_full_path(true, NULL, XBPS_REPOLIST);
	if (plist == NULL)
		return EINVAL;
	/*
	 * Get the dictionary with the list of registered repositories.
	 */
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

	iter = prop_array_iterator(array);
	if (iter == NULL) {
		prop_object_release(repolistd);
		return ENOMEM;
	}

	/*
	 * Iterate over the repository pool and find out if we have
	 * all available binary packages.
	 */
	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		plist =
		    xbps_get_pkg_index_plist(prop_string_cstring_nocopy(obj));
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
		 * This will find direct and indirect deps,
		 * if any of them is not there it will be added
		 * into the missing_deps array.
		 */
		rv = find_pkg_deps_from_repo(repod, pkg, pkg_rdeps);
		if (rv != 0) {
			if (rv == ENOENT) {
				rv = 0;
				prop_object_release(repod);
				continue;
			}
			prop_object_release(repod);
			break;
		}
		prop_object_release(repod);
	}

	missing_rdeps = prop_dictionary_get(chaindeps, "missing_deps");
	if (prop_array_count(missing_rdeps) == 0)
		goto out;

	/*
	 * If there are missing deps, iterate one more time
	 * just in case that indirect deps weren't found.
	 */
	prop_object_iterator_reset(iter);
	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		plist =
		    xbps_get_pkg_index_plist(prop_string_cstring_nocopy(obj));
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

		rv = find_pkg_missing_deps_from_repo(repod, pkg);
		if (rv != 0 && rv != ENOENT) {
			prop_object_release(repod);
			break;
		}

		prop_object_release(repod);
	}

out:
	prop_object_iterator_release(iter);
	prop_object_release(repolistd);

        return rv;
}

prop_dictionary_t
xbps_get_pkg_deps_dictionary(void)
{
	if (!deps_dict)
		return NULL;

	return prop_dictionary_copy(chaindeps);
}

static int
find_pkg_missing_deps_from_repo(prop_dictionary_t repo, prop_dictionary_t pkg)
{
	prop_array_t array;
	prop_dictionary_t curpkgd;
	prop_object_t obj;
	prop_object_iterator_t iter;
	const char *pkgname, *version;
	int rv = 0;

	assert(repo != NULL);
	assert(pkg != NULL);

	array = prop_dictionary_get(chaindeps, "missing_deps");
	if (prop_array_count(array) == 0)
		return 0;

	iter = prop_array_iterator(array);
	if (iter == NULL)
		return ENOMEM;

	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
		prop_dictionary_get_cstring_nocopy(obj, "version", &version);
		/*
		 * If required package is not in repo, add it into the
		 * missing deps array and pass to the next one.
		 */
		curpkgd = xbps_find_pkg_in_dict(repo, "packages", pkgname);
		if (curpkgd == NULL) {
			rv = add_missing_reqdep(pkgname, version);
			if (rv != 0 && rv != EEXIST)
				break;
			else {
				rv = ENOENT;
				continue;
			}
		}
		/*
		 * Package is on repo, add it into the dictionary.
		 */
		if ((rv = store_dependency(pkg, curpkgd, repo)) != 0)
			break;
		/*
		 * Remove package from missing now.
		 */
		rv = remove_missing_reqdep(pkgname);
		if (rv != 0 && rv != ENOENT)
			break;

		prop_object_iterator_reset(iter);
	}
	prop_object_iterator_release(iter);

	return rv;
}

static int
find_pkg_deps_from_repo(prop_dictionary_t repo, prop_dictionary_t pkg,
			prop_array_t pkg_rdeps)
{
	prop_dictionary_t curpkgd;
	prop_array_t curpkg_rdeps;
	prop_object_t obj;
	prop_object_iterator_t iter;
	const char *reqpkg, *reqvers;
	char *pkgname;
	int rv = 0;

	/*
	 * Package doesn't have deps, check to be sure.
	 */
	if (pkg_rdeps == NULL || prop_array_count(pkg_rdeps) == 0)
		return 0;

	iter = prop_array_iterator(pkg_rdeps);
	if (iter == NULL)
		return ENOMEM;
	/*
	 * Save the name of the origin package once.
	 */
	if (deps_dict == false) {
		deps_dict = true;
		rv = create_deps_dictionary();
		if (rv != 0) {
			prop_object_iterator_release(iter);
			return rv;
		}
		prop_dictionary_get_cstring_nocopy(pkg, "pkgname", &reqpkg);
		prop_dictionary_set_cstring_nocopy(chaindeps,
		    "origin", reqpkg);
	}

	/*
	 * Iterate over the list of required run dependencies for
	 * current package.
	 */
	while ((obj = prop_object_iterator_next(iter))) {
		reqpkg = prop_string_cstring_nocopy(obj);
		pkgname = xbps_get_pkg_name(reqpkg);
		reqvers = xbps_get_pkg_version(reqpkg);
		/*
		 * Check if required dep is satisfied and installed.
		 */
		if (xbps_check_is_installed_pkg(reqpkg) >= 0) {
			free(pkgname);
			continue;
		}
		/*
		 * Check if package is already added in the
		 * array of unsorted deps.
		 */
		if (xbps_find_pkg_in_dict(chaindeps, "unsorted_deps",
		    pkgname)) {
			free(pkgname);
			continue;
		}

		/*
		 * If required package is not in repo, add it into the
		 * missing deps array and pass to the next one.
		 */
		curpkgd = xbps_find_pkg_in_dict(repo, "packages", pkgname);
		if (curpkgd == NULL) {
			rv = add_missing_reqdep(pkgname, reqvers);
			free(pkgname);
			if (rv != 0 && rv != EEXIST)
				break;
			else {
				rv = ENOENT;
				continue;
			}
		}

		/*
		 * Package is on repo, add it into the dictionary.
		 */
		if ((rv = store_dependency(pkg, curpkgd, repo)) != 0) {
			free(pkgname);
			break;
		}

		/*
		 * Remove package from missing_deps now it's been found.
		 */
		rv = remove_missing_reqdep(pkgname);
		if (rv != 0 && rv != ENOENT) {
			free(pkgname);
			break;
		}
		free(pkgname);

		/*
		 * If package doesn't have rundeps, pass to the next one.
		 */
		curpkg_rdeps = prop_dictionary_get(curpkgd, "run_depends");
		if (curpkg_rdeps == NULL)
			continue;

		/*
		 * Iterate on required pkg to find more deps.
		 */
		if (!find_pkg_deps_from_repo(repo, curpkgd, curpkg_rdeps))
			continue;
	}
	prop_object_iterator_release(iter);

	return rv;
}

int
xbps_install_pkg_deps(const char *pkgname)
{
	prop_array_t required, missing;
	prop_object_t obj;
	prop_object_iterator_t iter;
	const char *repoloc;
	int rv = 0;

	/*
	 * If origin object in chaindeps is not the same, bail out.
	 */
	obj = prop_dictionary_get(chaindeps, "origin");
	if (obj == NULL || !prop_string_equals_cstring(obj, pkgname))
		return EINVAL;
	/*
	 * If there are missing deps, bail out.
	 */
	missing = prop_dictionary_get(chaindeps, "missing_deps");
	if (prop_array_count(missing) > 0)
		return ENOTSUP;
	/*
	 * Sort the dependency chain into an array.
	 */
	if ((rv = xbps_sort_pkg_deps(chaindeps)) != 0)
		return rv;

	required = prop_dictionary_get(chaindeps, "required_deps");
	if (required == NULL)
		return 0;

	iter = prop_array_iterator(required);
	if (iter == NULL)
		return ENOMEM;

	/*
	 * Check the SHA256 hash for any binary package that's going
	 * to be installed.
	 */
	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		prop_dictionary_get_cstring_nocopy(obj, "repository", &repoloc);
		rv = xbps_check_pkg_file_hash(obj, repoloc);
		if (rv != 0)
			goto out;
	}
	prop_object_iterator_reset(iter);

	/*
	 * Install all required dependencies, previously sorted.
	 */
	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		rv = xbps_install_binary_pkg_fini(NULL, obj);
		if (rv != 0)
			break;
	}

out:
	prop_object_iterator_release(iter);

	return rv;
}
