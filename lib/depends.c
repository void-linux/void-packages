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

static int	add_missing_reqdep(prop_dictionary_t, const char *,
				   const char *);
static int	find_repo_deps(prop_dictionary_t, prop_dictionary_t,
			       prop_dictionary_t, prop_array_t);
static int 	find_repo_missing_deps(prop_dictionary_t, prop_dictionary_t,
				       prop_dictionary_t);

static int
store_dependency(prop_dictionary_t master, prop_dictionary_t origind,
		 prop_dictionary_t depd, prop_dictionary_t repod)
{
	prop_dictionary_t dict;
	prop_array_t array;
	size_t dirdepscnt = 0, indirdepscnt = 0;
	const char *reqbyname, *repoloc, *originpkg;
	bool indirectdep = false;

	assert(origind != NULL);
	assert(depd != NULL);
	assert(repod != NULL);

	/*
	 * Get some info about dependencies and current repository.
	 */
	prop_dictionary_get_cstring_nocopy(origind, "pkgname", &reqbyname);
	prop_dictionary_get_cstring_nocopy(repod, "location-local", &repoloc);

	/*
	 * Required dependency is not installed. Check if it's
	 * already registered in the chain, and update some objects
	 * or add the object into array otherwise.
	 */
	prop_dictionary_get_cstring_nocopy(master, "origin", &originpkg);
	if (strcmp(originpkg, reqbyname)) {
		indirectdep = true;
		prop_dictionary_get_uint32(master, "indirectdeps_count",
		    &indirdepscnt);
		prop_dictionary_set_uint32(master, "indirectdeps_count",
		    ++indirdepscnt);
	} else {
		prop_dictionary_get_uint32(master, "directdeps_count",
		    &dirdepscnt);
		prop_dictionary_set_uint32(master, "directdeps_count",
		    ++dirdepscnt);
	}

	dict = prop_dictionary_copy(depd);
	if (dict == NULL)
		return errno;

	array = prop_dictionary_get(master, "unsorted_deps");
	if (array == NULL) {
		prop_object_release(dict);
		return errno;
	}
	/*
	 * Add required objects into package dep's dictionary.
	 */
	prop_dictionary_set_cstring(dict, "repository", repoloc);
	prop_dictionary_set_bool(dict, "indirect_dep", indirectdep);
	/*
	 * Remove some unneeded objects.
	 */
	prop_dictionary_remove(dict, "conf_files");
	prop_dictionary_remove(dict, "keep_dirs");
	prop_dictionary_remove(dict, "maintainer");
	prop_dictionary_remove(dict, "long_desc");

	/*
	 * Add the dictionary into the array.
	 */
	if (!xbps_add_obj_to_array(array, dict)) {
		prop_object_release(dict);
		return EINVAL;
	}

	return 0;
}

static int
add_missing_reqdep(prop_dictionary_t master, const char *pkgname,
		   const char *version)
{
	prop_array_t array;
	prop_dictionary_t depd;

	assert(master != NULL);
	assert(pkgname != NULL);
	assert(version != NULL);

	/*
	 * Adds a package into the missing deps array.
	 */
	if (xbps_find_pkg_in_dict(master, "missing_deps", pkgname))
		return EEXIST;

	array = prop_dictionary_get(master, "missing_deps");
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

int
xbps_find_deps_in_pkg(prop_dictionary_t master, prop_dictionary_t pkg,
		      prop_object_iterator_t iter)
{
	prop_array_t pkg_rdeps, missing_rdeps;
	prop_dictionary_t repod;
	prop_object_t obj;
	char *plist;
	int rv = 0;

	assert(pkg_props != NULL);
	assert(pkg != NULL);
	assert(iter != NULL);

	pkg_rdeps = prop_dictionary_get(pkg, "run_depends");
	if (pkg_rdeps == NULL)
		return 0;

	/*
	 * Iterate over the repository pool and find out if we have
	 * all available binary packages.
	 */
	while ((obj = prop_object_iterator_next(iter)) != NULL) {
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
		 * This will find direct and indirect deps,
		 * if any of them is not there it will be added
		 * into the missing_deps array.
		 */
		rv = find_repo_deps(master, repod, pkg, pkg_rdeps);
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

	missing_rdeps = prop_dictionary_get(master, "missing_deps");
	if (prop_array_count(missing_rdeps) == 0)
		return 0;

	/*
	 * If there are missing deps, iterate one more time
	 * just in case that indirect deps weren't found.
	 */
	prop_object_iterator_reset(iter);
	while ((obj = prop_object_iterator_next(iter)) != NULL) {
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

		rv = find_repo_missing_deps(master, repod, pkg);
		if (rv != 0 && rv != ENOENT) {
			prop_object_release(repod);
			return rv;
		}

		prop_object_release(repod);
	}

        return 0;
}

static int
find_repo_missing_deps(prop_dictionary_t master, prop_dictionary_t repo,
		       prop_dictionary_t pkg)
{
	prop_array_t array;
	prop_dictionary_t curpkgd;
	prop_object_t obj;
	prop_object_iterator_t iter;
	const char *pkgname, *version;
	int rv = 0;

	assert(repo != NULL);
	assert(pkg != NULL);

	array = prop_dictionary_get(master, "missing_deps");
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
			rv = add_missing_reqdep(master, pkgname, version);
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
		if ((rv = store_dependency(master, pkg, curpkgd, repo)) != 0)
			break;
		/*
		 * Remove package from missing_deps array now.
		 */
		rv = xbps_remove_pkg_from_dict(master,
		    "missing_deps", pkgname);
		if (rv != 0 && rv != ENOENT)
			break;

		prop_object_iterator_reset(iter);
	}
	prop_object_iterator_release(iter);

	return rv;
}

static int
find_repo_deps(prop_dictionary_t master, prop_dictionary_t repo,
	       prop_dictionary_t pkg, prop_array_t pkg_rdeps)
{
	prop_dictionary_t curpkgd;
	prop_array_t curpkg_rdeps;
	prop_object_t obj;
	prop_object_iterator_t iter;
	const char *reqpkg, *reqvers;
	char *pkgname;
	int rv = 0;

	iter = prop_array_iterator(pkg_rdeps);
	if (iter == NULL)
		return ENOMEM;

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
		if (xbps_find_pkg_in_dict(master, "unsorted_deps", pkgname)) {
			free(pkgname);
			continue;
		}
		/*
		 * If required package is not in repo, add it into the
		 * missing deps array and pass to the next one.
		 */
		curpkgd = xbps_find_pkg_in_dict(repo, "packages", pkgname);
		if (curpkgd == NULL) {
			rv = add_missing_reqdep(master, pkgname, reqvers);
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
		if ((rv = store_dependency(master, pkg, curpkgd, repo)) != 0) {
			free(pkgname);
			break;
		}
		/*
		 * Remove package from missing_deps now it's been found.
		 */
		rv = xbps_remove_pkg_from_dict(master,
		    "missing_deps", pkgname);
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
		if (!find_repo_deps(master, repo, curpkgd, curpkg_rdeps))
			continue;
	}
	prop_object_iterator_release(iter);

	return rv;
}
