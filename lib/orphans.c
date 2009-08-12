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

#include <xbps_api.h>

struct orphan_pkg {
	SIMPLEQ_ENTRY(orphan_pkg) chain;
	prop_dictionary_t dict;
	const char *pkgname;
};

static SIMPLEQ_HEAD(orphan_head, orphan_pkg) orphan_list =
    SIMPLEQ_HEAD_INITIALIZER(orphan_list);

static int
find_orphan_pkg(prop_object_t obj, void *arg, bool *loop_done)
{
	prop_array_t reqby;
	prop_object_t obj2;
	prop_object_iterator_t iter;
	struct orphan_pkg *orphan;
	char *pkgname;
	unsigned int ndep = 0, cnt = 0;
	bool automatic = false;

	(void)arg;
	(void)loop_done;

	if (!prop_dictionary_get_bool(obj, "automatic-install", &automatic))
		return EINVAL;

	if (!automatic)
		return 0;

	reqby = prop_dictionary_get(obj, "requiredby");
	if (reqby == NULL)
		return 0;
	else if (prop_object_type(reqby) != PROP_TYPE_ARRAY)
		return EINVAL;

	if ((cnt = prop_array_count(reqby)) == 0)
		goto add_orphan;

	iter = prop_array_iterator(reqby);
	if (iter == NULL)
		return errno;

	while ((obj2 = prop_object_iterator_next(iter)) != NULL) {
		pkgname = xbps_get_pkg_name(prop_string_cstring_nocopy(obj2));
		SIMPLEQ_FOREACH(orphan, &orphan_list, chain) {
			if (strcmp(orphan->pkgname, pkgname) == 0) {
				ndep++;
				break;
			}
		}
		free(pkgname);
	}
	prop_object_iterator_release(iter);
	if (ndep != cnt)
		return 0;

add_orphan:
	orphan = NULL;
	orphan = malloc(sizeof(struct orphan_pkg));
	if (orphan == NULL)
		return errno;

	prop_dictionary_get_cstring_nocopy(obj, "pkgname", &orphan->pkgname);
	orphan->dict = prop_dictionary_copy(obj);
	SIMPLEQ_INSERT_TAIL(&orphan_list, orphan, chain);

	return 0;
}

static void
cleanup(void)
{
	struct orphan_pkg *orphan;

	while ((orphan = SIMPLEQ_FIRST(&orphan_list)) != NULL) {
		SIMPLEQ_REMOVE(&orphan_list, orphan, orphan_pkg, chain);
		prop_object_release(orphan->dict);
		free(orphan);
	}
}

prop_array_t
xbps_find_orphan_packages(void)
{
	prop_array_t array;
	prop_dictionary_t dict;
	struct orphan_pkg *orphan;
	int rv = 0;

	if ((dict = xbps_prepare_regpkgdb_dict()) == NULL)
		return NULL;
	/*
	 * Find out all orphan packages by looking at the
	 * regpkgdb dictionary and we must do that in reverse order.
	 */
	rv = xbps_callback_array_iter_reverse_in_dict(dict, "packages",
	    find_orphan_pkg, NULL);
	if (rv != 0) {
		cleanup();
		return NULL;
	}
	/*
	 * Prepare an array with all packages previously found. We
	 * do this in that way to do a reverse order in which the
	 * packages were installed.
	 */
	array = prop_array_create();
	if (array == NULL) {
		cleanup();
		return NULL;
	}
	while ((orphan = SIMPLEQ_FIRST(&orphan_list)) != NULL) {
		prop_array_add(array, orphan->dict);
		SIMPLEQ_REMOVE(&orphan_list, orphan, orphan_pkg, chain);
		prop_object_release(orphan->dict);
		free(orphan);
	}

	return array;
}
