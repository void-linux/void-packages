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
#include <unistd.h>

#include <xbps_api.h>

struct orphan {
	prop_array_t array;
	const char *pkgname;
	const char *version;
};

static int
find_orphan_pkg(prop_object_t obj, void *arg, bool *loop_done)
{
	struct orphan *orphan = arg;
	prop_array_t reqby;
	bool automatic = false;

	(void)loop_done;

	reqby = prop_dictionary_get(obj, "requiredby");
	if (reqby != NULL && prop_array_count(reqby) > 0)
		return 0;

	if (!prop_dictionary_get_bool(obj, "automatic-install", &automatic))
		return EINVAL;

	if (automatic)
		if (!prop_array_add(orphan->array, obj))
			return EINVAL;

	return 0;
}

static int
find_indirect_orphan_pkg(prop_object_t obj, void *arg, bool *loop_done)
{
	struct orphan *orphan = arg;
	prop_array_t reqby;
	char *pkg;
	bool automatic = false;

	(void)loop_done;

	if (!prop_dictionary_get_bool(obj, "automatic-install", &automatic))
		return EINVAL;

	if (!automatic)
		return 0;

	reqby = prop_dictionary_get(obj, "requiredby");
	if (reqby == NULL || prop_array_count(reqby) != 1)
		return 0;

	pkg = xbps_xasprintf("%s-%s", orphan->pkgname, orphan->version);
	if (pkg == NULL)
		return ENOMEM;

	if (xbps_find_string_in_array(reqby, pkg)) {
		if (!prop_array_add(orphan->array, obj)) {
			free(pkg);
			return EINVAL;
		}
	}
	free(pkg);

	return 0;
}

prop_array_t
xbps_find_orphan_packages(void)
{
	prop_dictionary_t dict;
	prop_object_t obj;
	prop_object_iterator_t iter;
	struct orphan orphan;
	const char *rootdir;
	char *plist;
	int rv = 0;

	rootdir = xbps_get_rootdir();
	plist = xbps_xasprintf("%s/%s/%s", rootdir,
	    XBPS_META_PATH, XBPS_REGPKGDB);
	if (plist == NULL)
		return NULL;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		free(plist);
		return NULL;
	}
	free(plist);

	orphan.array = prop_array_create();
	if (orphan.array == NULL) {
		prop_object_release(dict);
		return NULL;
	}

	/*
	 * First look for direct orphan packages, i.e the ones
	 * that were required directly by a previous removed package.
	 */
	rv = xbps_callback_array_iter_in_dict(dict, "packages",
	    find_orphan_pkg, (void *)&orphan);
	if (rv != 0) {
		prop_object_release(dict);
		prop_object_release(orphan.array);
		return NULL;
	}

	/*
	 * Now look if any of these packages have dependencies that
	 * were installed indirectly by some removed package.
	 */
	iter = prop_array_iterator(orphan.array);
	if (iter == NULL) {
		prop_object_release(dict);
		prop_object_release(orphan.array);
		return NULL;
	}

	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname",
		    &orphan.pkgname);
		prop_dictionary_get_cstring_nocopy(obj, "version",
		    &orphan.version);
		rv = xbps_callback_array_iter_in_dict(dict, "packages",
		    find_indirect_orphan_pkg, (void *)&orphan);
		if (rv != 0) {
			prop_object_iterator_release(iter);
			prop_object_release(dict);
			prop_object_release(orphan.array);
			return NULL;
		}
	}
	prop_object_iterator_release(iter);
	prop_object_release(dict);

	return orphan.array;
}
