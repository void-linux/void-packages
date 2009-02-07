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
static int	check_missing_reqdep(const char *, const char *, size_t *);
static void	remove_missing_reqdep(size_t *);

static prop_dictionary_t chaindeps;

/*
 * Creates the dictionary to store the dependency chain.
 */
static int
create_deps_dictionary(void)
{
	prop_array_t installed, direct, indirect, missing;
	int rv = 0;

	chaindeps = prop_dictionary_create();
	if (chaindeps == NULL)
		return ENOMEM;

	missing = prop_array_create();
	if (missing == NULL) {
		rv = ENOMEM;
		goto fail;
	}

	installed = prop_array_create();
	if (installed == NULL) {
		rv = ENOMEM;
		goto fail2;
	}

	direct = prop_array_create();
	if (direct == NULL) {
		rv = ENOMEM;
		goto fail3;
	}

	indirect = prop_array_create();
	if (indirect == NULL) {
		rv = ENOMEM;
		goto fail4;
	}

	if (!xbps_add_obj_to_dict(chaindeps, missing, "missing_deps")) {
		rv = EINVAL;
		goto fail5;
	}
	if (!xbps_add_obj_to_dict(chaindeps, installed, "installed_deps")) {
		rv = EINVAL;
		goto fail5;
	}
	if (!xbps_add_obj_to_dict(chaindeps, direct, "direct_deps")) {
		rv = EINVAL;
		goto fail5;
	}
	if (!xbps_add_obj_to_dict(chaindeps, indirect, "indirect_deps")) {
		rv = EINVAL;
		goto fail5;
	}
	return rv;

fail5:
	prop_object_release(indirect);
fail4:
	prop_object_release(direct);
fail3:
	prop_object_release(installed);
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
	prop_dictionary_t dict, curpkgdir, curpkgindir;
	prop_array_t array;
	uint32_t prio = 0;
	size_t len = 0;
	const char *pkgname, *version, *reqbyname, *reqbyver;
	const char  *repoloc, *binfile, *array_key = NULL, *originpkg;
	char *reqby;
	int rv = 0;

	assert(origind != NULL);
	assert(depd != NULL);
	assert(repod != NULL);

	/*
	 * Get some info about dependencies and current repository.
	 */
	prop_dictionary_get_cstring_nocopy(depd, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(depd, "version", &version);
	prop_dictionary_get_cstring_nocopy(depd, "filename", &binfile);
	prop_dictionary_get_uint32(depd, "priority", &prio);
	prop_dictionary_get_cstring_nocopy(origind, "pkgname", &reqbyname);
	prop_dictionary_get_cstring_nocopy(origind, "version", &reqbyver);
	prop_dictionary_get_cstring_nocopy(repod, "location-local", &repoloc);

	len = strlen(reqbyname) + strlen(reqbyver) + 2;
	reqby = malloc(len + 1);
	if (reqby == NULL)
		return ENOMEM;

	(void)snprintf(reqby, len, "%s-%s", reqbyname, reqbyver);

	/*
	 * Check if dependency is already installed to select the
	 * correct array object.
	 */
	if (xbps_check_is_installed_pkgname(pkgname)) {
		/*
		 * Dependency is already installed.
		 */
		array_key = "installed_deps";
		dict = xbps_find_pkg_in_dict(chaindeps, array_key, pkgname);
		if (dict)
			goto out;
	} else {
		/*
		 * Required dependency is not installed. Check if it's
		 * already registered in the chain, and update priority
		 * or add the object into array otherwise.
		 */
		prop_dictionary_get_cstring_nocopy(chaindeps, "origin",
		    &originpkg);
		curpkgdir = xbps_find_pkg_in_dict(chaindeps,
		    "direct_deps", pkgname);
		curpkgindir = xbps_find_pkg_in_dict(chaindeps,
		    "indirect_deps", pkgname);

		if (strcmp(originpkg, reqbyname) == 0)
			array_key = "direct_deps";
		else
			array_key = "indirect_deps";

		if (curpkgdir && curpkgindir) {
			goto out;

		} else if (curpkgdir) {
			/*
			 * Update the priority.
			 */
			prop_dictionary_get_uint32(curpkgdir,
			    "priority", &prio);
			prop_dictionary_set_uint32(curpkgdir,
			    "priority", ++prio);
			goto out;
		} else if (curpkgindir) {
			prop_dictionary_get_uint32(curpkgindir,
			    "priority", &prio);
			prop_dictionary_set_uint32(curpkgindir,
			    "priority", ++prio);
			goto out;
		}
	}

	/*
	 * Create package dep's dictionary and array.
	 */
	dict = prop_dictionary_create();
	if (dict == NULL) {
		rv = ENOMEM;
		goto out;
	}

	array = prop_dictionary_get(chaindeps, array_key);
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
	prop_dictionary_set_cstring(dict, "requiredby", reqby);

	if ((strcmp(array_key, "direct_deps") == 0) ||
	    (strcmp(array_key, "indirect_deps") == 0)) {
		prop_dictionary_set_cstring(dict, "repository", repoloc);
		prop_dictionary_set_cstring(dict, "filename", binfile);
		prop_dictionary_set_uint32(dict, "priority", prio);
	}
	/*
	 * Add the dictionary into the array.
	 */
	if (!xbps_add_obj_to_array(array, dict)) {
		prop_object_release(dict);
		rv = EINVAL;
		goto out;
	}

out:
	free(reqby);

	return rv;
}

static int
add_missing_reqdep(const char *pkgname, const char *version)
{
	prop_array_t array;
	prop_dictionary_t depd;
	size_t idx = 0;

	assert(pkgname != NULL);
	assert(version != NULL);

	if (check_missing_reqdep(pkgname, version, &idx) == 0)
		return EEXIST;

	array = prop_dictionary_get(chaindeps, "missing_deps");
	depd = prop_dictionary_create();
	if (depd == NULL)
		return ENOMEM;

	prop_dictionary_set_cstring_nocopy(depd, "pkgname", pkgname);
	prop_dictionary_set_cstring_nocopy(depd, "version", version);
	if (!xbps_add_obj_to_array(array, depd)) {
		prop_object_release(depd);
		return EINVAL;
	}

	return 0;
}

static int
check_missing_reqdep(const char *pkgname, const char *version,
		     size_t *idx)
{
	prop_array_t array;
	prop_object_t obj;
	prop_object_iterator_t iter;
	const char *missname, *missver;
	size_t lidx = 0;
	int rv = 0;

	assert(pkgname != NULL);
	assert(version != NULL);
	assert(idx != NULL);

	array = prop_dictionary_get(chaindeps, "missing_deps");
	assert(array != NULL);

	iter = prop_array_iterator(array);
	if (iter == NULL)
		return ENOMEM;

	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &missname);
		prop_dictionary_get_cstring_nocopy(obj, "version", &missver);
		if ((strcmp(pkgname, missname) == 0) &&
		    (strcmp(version, missver) == 0)) {
			*idx = lidx;
			goto out;
		}
		idx++;
	}

	rv = ENOENT;

out:
	prop_object_iterator_release(iter);
	return rv;
}

static void
remove_missing_reqdep(size_t *idx)
{
	prop_array_t array;

	array = prop_dictionary_get(chaindeps, "missing_deps");
	assert(array != NULL);
	prop_array_remove(array, *idx);
}

int
xbps_find_deps_in_pkg(prop_dictionary_t repo, prop_dictionary_t pkg)
{
	prop_dictionary_t pkgdict;
	prop_array_t array;
	prop_object_t obj;
	prop_object_iterator_t iter;
	size_t idx = 0;
	const char *reqpkg, *reqvers;
	char *pkgname;
	int rv = 0;
	static bool deps_dict;

	array = prop_dictionary_get(pkg, "run_depends");
	if (array == NULL || prop_array_count(array) == 0)
		return 0;

	iter = prop_array_iterator(array);
	if (iter == NULL)
		return ENOMEM;

	if (deps_dict == false) {
		deps_dict = true;
		rv = create_deps_dictionary();
		if (rv != 0)
			goto out;

		prop_dictionary_get_cstring_nocopy(pkg, "pkgname", &reqpkg);
		prop_dictionary_set_cstring_nocopy(chaindeps,
		    "origin", reqpkg);
	}

	/*
	 * Iterate over the list of required run dependencies for
	 * a package.
	 */
	while ((obj = prop_object_iterator_next(iter))) {
		/*
		 * If required package is not in repo, add it into the
		 * missing deps array and pass to the next one.
		 */
		reqpkg = prop_string_cstring_nocopy(obj);
		pkgname = xbps_get_pkg_name(reqpkg);
		reqvers = xbps_get_pkg_version(reqpkg);
		pkgdict = xbps_find_pkg_in_dict(repo, "packages", pkgname);
		if (pkgdict == NULL) {
			rv = add_missing_reqdep(pkgname, reqvers);
			free(pkgname);
			if (rv != 0 && rv != EEXIST)
				break;
			else if (rv == EEXIST)
				continue;
			else {
				rv = XBPS_PKG_ENOTINREPO;
				continue;
			}
		}

		/*
		 * Check if dependency wasn't found before.
		 */
		rv = check_missing_reqdep(pkgname, reqvers, &idx);
		free(pkgname);
		if (rv == 0) {
			/* 
 			 * Found in current repository, remove it.
 			 */
			remove_missing_reqdep(&idx);

		} else if (rv != 0 && rv != ENOENT)
			break;
		
		/*
		 * Package is on repo, add it into the dictionary.
		 */
		if ((rv = store_dependency(pkg, pkgdict, repo)) != 0)
			break;
		/*
		 * Iterate on required pkg to find more deps.
		 */
		if (!xbps_find_deps_in_pkg(repo, pkgdict))
			continue;
	}

out:
	prop_object_iterator_release(iter);

	return rv;
}

int
xbps_install_pkg_deps(prop_dictionary_t pkg)
{
	prop_array_t array, installed, direct, indirect;
	prop_dictionary_t dict;
	prop_object_t obj;
	prop_object_iterator_t iter;
	uint32_t maxprio = 0, prio = 0;
	size_t curidx = 0, idx = 0;
	const char *array_key, *reqby, *curname;
	int rv = 0;

	assert(pkg != NULL);

	/*
	 * Install required dependencies of a package.
	 * The order for installation will be:
	 *
	 * 	- Indirect deps with high->low prio.
	 * 	- Direct deps with high->low prio.
	 */

	/*
	 * First case: all deps are satisfied.
	 */
	installed = prop_dictionary_get(chaindeps, "installed_deps");
	direct = prop_dictionary_get(chaindeps, "direct_deps");
	indirect = prop_dictionary_get(chaindeps, "indirect_deps");
	if (prop_array_count(direct) == 0 && prop_array_count(indirect) == 0 &&
	    prop_array_count(installed) > 0)
		return 0;

	/*
	 * Second case: only direct deps are required.
	 */
	if (prop_array_count(indirect) == 0 && prop_array_count(direct) > 0)
		array_key = "direct_deps";
	else
		array_key = "indirect_deps";

again:
	array = prop_dictionary_get(chaindeps, array_key);
	if (array == NULL || prop_array_count(array) == 0) {
		rv = EINVAL;
		goto out;
	}

	iter = prop_array_iterator(array);
	if (iter == NULL) {
		rv = ENOMEM;
		goto out;
	}

	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		prop_dictionary_get_uint32(obj, "priority", &prio);
		if (maxprio < prio) {
			curidx = idx;
			maxprio = prio;
		}
		idx++;
	}
	prop_object_iterator_release(iter);

	dict = prop_array_get(array, curidx);
	if (dict == NULL) {
		rv = ENOENT;
		goto out;
	}

	prop_dictionary_get_cstring_nocopy(dict, "pkgname", &curname);
	prop_dictionary_get_cstring_nocopy(dict, "requiredby", &reqby);
	printf("[%s] %s requiredby %s prio %u\n",
	    strcmp(array_key, "indirect_deps") == 0 ? "INDIRECT" : "DIRECT",
	    curname, reqby, maxprio);

	prop_array_remove(array, curidx);
	if (prop_array_count(array) > 0) {
		prio = maxprio = 0;
		curidx = idx = 0;
		goto again;
	} else {
		prio = maxprio = 0;
		curidx = idx = 0;
		array_key = "direct_deps";
		goto again;
	}

out:
	prop_object_release(chaindeps);
	exit(0);

	return rv;
}
