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
	TAILQ_ENTRY(sorted_dependency) chain;
	prop_dictionary_t dict;
	size_t idx;
	ssize_t newidx;
	bool unsorted;
	bool reorg;
};

static TAILQ_HEAD(sdep_head, sorted_dependency) sdep_list =
    TAILQ_HEAD_INITIALIZER(sdep_list);

static ssize_t
find_pkgdict_with_highest_prio(prop_array_t array, uint32_t *maxprio,
			       bool do_indirect)
{
	prop_object_t obj;
	prop_object_iterator_t iter;
	uint32_t prio = 0;
	size_t idx = 0;
	ssize_t curidx = -1;
	bool indirect;

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
		prop_dictionary_get_bool(obj, "indirect_dep", &indirect);

		if (do_indirect) {
			if ((*maxprio <= prio) && indirect) {
				curidx = idx;
				*maxprio = prio;
			}
		} else {
			if ((*maxprio <= prio) && !indirect) {
				curidx = idx;
				*maxprio = prio;
			}
		}
		idx++;
	}
	prop_object_iterator_release(iter);

	if (curidx == -1)
		errno = ENOENT;

	return curidx;
}

static struct sorted_dependency *
find_sorteddep_by_name(const char *pkgname)
{
	struct sorted_dependency *sdep;
	const char *curname;

	TAILQ_FOREACH(sdep, &sdep_list, chain) {
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
	prop_array_t installed, sorted, unsorted, rundeps_array;
	prop_dictionary_t dict;
	prop_object_t obj;
	prop_object_iterator_t iter;
	struct sorted_dependency *sdep, *sdep2;
	uint32_t maxprio = 0;
	size_t curidx = 0, indirdepscnt = 0, dirdepscnt = 0, cnt = 0;
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
	installed = prop_dictionary_get(chaindeps, "installed_deps");
	unsorted = prop_dictionary_get(chaindeps, "unsorted_deps");
	if (prop_array_count(unsorted) == 0 && prop_array_count(installed) > 0)
		return 0;

	prop_dictionary_get_uint32(chaindeps, "indirectdeps_count",
	    &indirdepscnt);
	prop_dictionary_get_uint32(chaindeps, "directdeps_count",
	    &dirdepscnt);
	unsorted = prop_dictionary_get(chaindeps, "unsorted_deps");
	/*
	 * Pass 1: order indirect deps by priority.
	 */
	while (cnt < indirdepscnt) {
		curidx = find_pkgdict_with_highest_prio(unsorted,
		    &maxprio, true);
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
		sdep->newidx = -1;
		TAILQ_INSERT_TAIL(&sdep_list, sdep, chain);
		prop_array_remove(unsorted, curidx);
		maxprio = 0;
		cnt++;
	}

	cnt = 0;
	/*
	 * Pass 2: order direct deps by priority.
	 */
	while (cnt < dirdepscnt) {
		curidx = find_pkgdict_with_highest_prio(unsorted,
		    &maxprio, false);
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
		sdep->idx = cnt + indirdepscnt;
		sdep->newidx = -1;
		TAILQ_INSERT_TAIL(&sdep_list, sdep, chain);
		prop_array_remove(unsorted, curidx);
		maxprio = 0;
		cnt++;
	}

	/*
	 * Pass 3: update new index position by looking at run_depends and
	 * its current index position.
	 */
	TAILQ_FOREACH(sdep, &sdep_list, chain) {
		prop_dictionary_get_cstring_nocopy(sdep->dict,
		    "pkgname", &curpkg);
		rundeps_array = prop_dictionary_get(sdep->dict, "run_depends");
		if (rundeps_array == NULL)
			continue;

		iter = prop_array_iterator(rundeps_array);
		if (iter == NULL) {
			rv = ENOMEM;
			goto out;
		}
		curidx = sdep->idx;

		while ((obj = prop_object_iterator_next(iter)) != NULL) {
			rundep = prop_string_cstring_nocopy(obj);
			pkgname = xbps_get_pkg_name(rundep);
			/*
			 * If package is installed, pass to the next one.
			 */
			if (xbps_check_is_installed_pkgname(pkgname)) {
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
			/*
			 * If required dependency is before current package,
			 * pass to the next one.
			 */
			if (curidx > sdep2->idx)
				continue;
			/*
			 * Update index position for the two objects.
			 */
			if (!sdep2->unsorted) {
				sdep2->unsorted = true;
				sdep2->newidx = curidx;
				sdep->newidx = curidx + 1;
			}
		}
		prop_object_iterator_release(iter);
	}
	prop_dictionary_remove(chaindeps, "unsorted_deps");

	/*
	 * Pass 4: copy dictionaries into the final array with the
	 * correct index position for all dependencies.
	 */
	TAILQ_FOREACH(sdep, &sdep_list, chain) {
		if (sdep->reorg)
			continue;

		if (sdep->newidx != -1) {
			TAILQ_FOREACH(sdep2, &sdep_list, chain) {
				if (sdep2->unsorted) {
					if (!prop_array_set(sorted,
					    sdep2->newidx, sdep2->dict)) {
						rv = errno;
						goto out;
					}
					sdep2->newidx = -1;
					sdep2->unsorted = false;
					sdep2->reorg = true;
					break;
				}
			}
			if (!prop_array_set(sorted, sdep->newidx, sdep->dict)) {
				rv = errno;
				goto out;
			}
			sdep->newidx = -1;
		} else {
			if (!prop_array_add(sorted, sdep->dict)) {
				rv = errno;
				goto out;
			}
		}
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
	while ((sdep = TAILQ_FIRST(&sdep_list)) != NULL) {
		TAILQ_REMOVE(&sdep_list, sdep, chain);
		prop_object_release(sdep->dict);
		free(sdep);
	}

	return rv;
}
