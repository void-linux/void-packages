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

#include <xbps_api.h>

struct sorted_dependency {
	SIMPLEQ_ENTRY(sorted_dependency) chain;
	prop_dictionary_t dict;
	prop_array_t reqby;
	size_t idx;
	size_t prio;
};

static SIMPLEQ_HEAD(sdep_head, sorted_dependency) sdep_list =
    SIMPLEQ_HEAD_INITIALIZER(sdep_list);

static ssize_t
find_pkgdict_with_highest_prio(prop_array_t array, uint32_t *maxprio)
{
	prop_object_t obj;
	prop_object_iterator_t iter;
	uint32_t prio = 0;
	size_t idx = 0;
	ssize_t curidx = -1;

	assert(array != NULL);

	iter = prop_array_iterator(array);
	if (iter == NULL) {
		errno = ENOMEM;
		return -1;
	}
	/*
	 * Finds the index of a package with the highest priority.
	 */
	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		prop_dictionary_get_uint32(obj, "priority", &prio);
		if (*maxprio <= prio) {
			curidx = idx;
			*maxprio = prio;
		}
		idx++;
	}
	prop_object_iterator_release(iter);

	if (curidx == -1)
		errno = ENOENT;

	return curidx;
}

static struct sorted_dependency *
find_sorteddep_with_highest_prio(void)
{
	struct sorted_dependency *sdep;
	size_t maxprio = 0;
	size_t curidx = 0, idx = 0;

	SIMPLEQ_FOREACH(sdep, &sdep_list, chain) {
		if (maxprio <= sdep->prio) {
			curidx = idx;
			maxprio = sdep->prio;
		}
		idx++;
	}

	idx = 0;
	SIMPLEQ_FOREACH(sdep, &sdep_list, chain) {
		if (idx == curidx)
			break;
		idx++;
	}

	return sdep;
}

static struct sorted_dependency *
find_sorteddep_by_name(const char *pkgname)
{
	struct sorted_dependency *sdep;
	const char *curname;

	SIMPLEQ_FOREACH(sdep, &sdep_list, chain) {
		prop_dictionary_get_cstring_nocopy(sdep->dict,
		    "pkgname", &curname);
		if (strcmp(pkgname, curname) == 0)
			break;
	}

	return sdep;
}

int
xbps_sort_pkg_deps(prop_dictionary_t chaindeps)
{
	prop_array_t sorted, unsorted, rundeps_array, reqby;
	prop_dictionary_t dict;
	prop_object_t obj;
	prop_object_iterator_t iter;
	struct sorted_dependency *sdep, *sdep2;
	uint32_t maxprio = 0;
	size_t indirdepscnt = 0, dirdepscnt = 0, cnt = 0;
	ssize_t curidx = 0;
	const char *curpkg, *rundep;
	char *pkgname;
	int rv = 0;

	assert(chaindeps != NULL);

	sorted = prop_array_create();
	if (sorted == NULL)
		return ENOMEM;

	/*
	 * All required deps are satisfied (already installed).
	 */
	unsorted = prop_dictionary_get(chaindeps, "unsorted_deps");
	if (prop_array_count(unsorted) == 0) {
		prop_object_release(sorted);
		return 0;
	}

	prop_dictionary_get_uint32(chaindeps, "indirectdeps_count",
	    &indirdepscnt);
	prop_dictionary_get_uint32(chaindeps, "directdeps_count",
	    &dirdepscnt);
	unsorted = prop_dictionary_get(chaindeps, "unsorted_deps");
	/*
	 * Pass 1: order all deps (direct/indirect) by priority.
	 */
	while (cnt < dirdepscnt + indirdepscnt) {
		curidx = find_pkgdict_with_highest_prio(unsorted, &maxprio);
		if (curidx == -1) {
			rv = errno;
			goto out;
		}
		dict = prop_array_get(unsorted, curidx);
		if (dict == NULL) {
			rv = errno;
			goto out;
		}
		sdep = calloc(1, sizeof(*sdep));
		if (sdep == NULL) {
			rv = ENOMEM;
			goto out;
		}
		sdep->dict = prop_dictionary_copy(dict);
		sdep->idx = cnt;
		prop_dictionary_get_uint32(dict, "priority", &sdep->prio);
		reqby = prop_dictionary_get(dict, "required_by");
		if (reqby && prop_array_count(reqby) > 0)
			sdep->reqby = prop_array_copy(reqby);
		SIMPLEQ_INSERT_TAIL(&sdep_list, sdep, chain);
		prop_array_remove(unsorted, curidx);
		maxprio = 0;
		cnt++;
	}

	/*
	 * Pass 2: increase priority of dependencies any time
	 * a package requires them.
	 */
	SIMPLEQ_FOREACH(sdep, &sdep_list, chain) {
		prop_dictionary_get_cstring_nocopy(sdep->dict,
		    "pkgname", &curpkg);
		rundeps_array = prop_dictionary_get(sdep->dict, "run_depends");
		if (rundeps_array == NULL) {
			sdep->prio += 4;
			continue;
		}

		iter = prop_array_iterator(rundeps_array);
		if (iter == NULL) {
			rv = ENOMEM;
			goto out;
		}

		while ((obj = prop_object_iterator_next(iter)) != NULL) {
			rundep = prop_string_cstring_nocopy(obj);
			pkgname = xbps_get_pkg_name(rundep);
			/*
			 * If package is installed, pass to the next one.
			 */
			if (xbps_check_is_installed_pkg(rundep) == 0) {
				free(pkgname);
				continue;
			}
			/* Ignore itself */
			if (strcmp(curpkg, pkgname) == 0) {
				free(pkgname);
				continue;
			}

			sdep2 = find_sorteddep_by_name(pkgname);
			free(pkgname);
			sdep2->prio++;
		}
		prop_object_iterator_release(iter);
	}
	prop_dictionary_remove(chaindeps, "unsorted_deps");

	/*
	 * Pass 3: increase priority of a package, by looking at
	 * its required_by array member's priority.
	 */
	SIMPLEQ_FOREACH(sdep, &sdep_list, chain) {
		iter = prop_array_iterator(sdep->reqby);
		if (iter == NULL)
			continue;

		while ((obj = prop_object_iterator_next(iter))) {
			rundep = prop_string_cstring_nocopy(obj);
			pkgname = xbps_get_pkg_name(rundep);
			sdep2 = find_sorteddep_by_name(pkgname);
			if (sdep2 == NULL) {
				free(pkgname);
				continue;
			}
			free(pkgname);
			sdep->prio += sdep2->prio + 1;
		}
		prop_object_iterator_release(iter);
	}

	/*
	 * Pass 4: copy dictionaries into the final array with the
	 * correct index position for all dependencies and release
	 * resources used by the sorting passes.
	 */
	while ((sdep = find_sorteddep_with_highest_prio()) != NULL) {
		prop_array_add(sorted, sdep->dict);
		SIMPLEQ_REMOVE(&sdep_list, sdep, sorted_dependency, chain);
		prop_object_release(sdep->dict);
		prop_object_release(sdep->reqby);
		free(sdep);
	}

	/*
	 * Sanity check that the array contains the same number of
	 * objects than the total number of required dependencies.
	 */
	cnt = dirdepscnt + indirdepscnt;
	if (cnt != prop_array_count(sorted)) {
		rv = EINVAL;
		goto out;
	}

	if (!prop_dictionary_set(chaindeps, "required_deps", sorted))
		rv = EINVAL;
out:
	/*
	 * Release resources used by temporary sorting.
	 */
	prop_object_release(sorted);
	while ((sdep = SIMPLEQ_FIRST(&sdep_list)) != NULL) {
		SIMPLEQ_REMOVE(&sdep_list, sdep, sorted_dependency, chain);
		prop_object_release(sdep->dict);
		prop_object_release(sdep->reqby);
		free(sdep);
	}

	return rv;
}
