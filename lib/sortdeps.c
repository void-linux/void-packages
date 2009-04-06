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
};

static SIMPLEQ_HEAD(sdep_head, sorted_dependency) sdep_list =
    SIMPLEQ_HEAD_INITIALIZER(sdep_list);

static struct sorted_dependency *
find_sorteddep_by_name(const char *pkgname)
{
	struct sorted_dependency *sdep = NULL;
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
	prop_array_t sorted, unsorted, rundeps;
	prop_object_t obj, obj2;
	prop_object_iterator_t iter, iter2;
	struct sorted_dependency *sdep;
	size_t indirdepscnt = 0, dirdepscnt = 0, rundepscnt = 0, cnt = 0;
	const char *pkgname;
	char *curpkgnamedep;
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

	iter = prop_array_iterator(unsorted);
	if (iter == NULL) {
		prop_object_release(sorted);
		return ENOMEM;
	}
again:
	/*
	 * Order all deps by looking at its run_depends array.
	 */
	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
		if (find_sorteddep_by_name(pkgname) != NULL)
			continue;

		sdep = malloc(sizeof(*sdep));
		if (sdep == NULL) {
			rv = ENOMEM;
			goto out;
		}
		/*
		 * Packages that don't have deps go unsorted, because
		 * it doesn't matter.
		 */
		rundeps = prop_dictionary_get(obj, "run_depends");
		if (rundeps == NULL || prop_array_count(rundeps) == 0) {
			sdep->dict = prop_dictionary_copy(obj);
			SIMPLEQ_INSERT_TAIL(&sdep_list, sdep, chain);
			cnt++;
			continue;
		}
		iter2 = prop_array_iterator(rundeps);
		if (iter2 == NULL) {
			free(sdep);
			rv = ENOMEM;
			goto out;
		}
		/*
		 * Iterate over the run_depends array, and find out if they
		 * were already added in the sorted list.
		 */
		while ((obj2 = prop_object_iterator_next(iter2)) != NULL) {
			curpkgnamedep =
			    xbps_get_pkg_name(prop_string_cstring_nocopy(obj2));
			/*
			 * If dependency is already installed or queued,
			 * pass to the next one.
			 */
			if (xbps_check_is_installed_pkgname(curpkgnamedep))
				rundepscnt++;
			else if (find_sorteddep_by_name(curpkgnamedep) != NULL)
				rundepscnt++;

			free(curpkgnamedep);
		}
		prop_object_iterator_release(iter2);

		/* Add dependency if all its required deps are already added */
		if (rundepscnt != 0 &&
		   (prop_array_count(rundeps) == rundepscnt)) {
			sdep->dict = prop_dictionary_copy(obj);
			SIMPLEQ_INSERT_TAIL(&sdep_list, sdep, chain);
			rundepscnt = 0;
			cnt++;
			continue;
		}
		free(sdep);
		rundepscnt = 0;
	}

	/* Iterate until all deps are processed. */
	if (cnt < dirdepscnt + indirdepscnt) {
		prop_object_iterator_reset(iter);
		goto again;
	}
	prop_object_iterator_release(iter);

	/*
	 * Add all sorted dependencies into the sorted deps array.
	 */
	while ((sdep = SIMPLEQ_FIRST(&sdep_list)) != NULL) {
		prop_array_add(sorted, sdep->dict);
		SIMPLEQ_REMOVE(&sdep_list, sdep, sorted_dependency, chain);
		prop_object_release(sdep->dict);
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
		free(sdep);
	}

	return rv;
}
