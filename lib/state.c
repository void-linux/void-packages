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

static int
set_new_state(prop_dictionary_t dict, pkg_state_t state)
{
	const char *state_str;

	assert(dict != NULL);

	switch (state) {
	case XBPS_PKG_STATE_UNPACKED:
		state_str = "unpacked";
		break;
	case XBPS_PKG_STATE_INSTALLED:
		state_str = "installed";
		break;
	case XBPS_PKG_STATE_BROKEN:
		state_str = "broken";
		break;
	case XBPS_PKG_STATE_CONFIG_FILES:
		state_str = "config-files";
		break;
	case XBPS_PKG_STATE_NOT_INSTALLED:
		state_str = "not-installed";
		break;
	default:
		return -1;
	}

	if (!prop_dictionary_set_cstring_nocopy(dict, "state", state_str))
		return -1;

	return 0;
}

static pkg_state_t
get_state(prop_dictionary_t dict)
{
	const char *state_str;
	pkg_state_t state = 0;

	assert(dict != NULL);

	prop_dictionary_get_cstring_nocopy(dict, "state", &state_str);
	if (state_str == NULL)
		return 0;

	if (strcmp(state_str, "unpacked") == 0)
		state = XBPS_PKG_STATE_UNPACKED;
	else if (strcmp(state_str, "installed") == 0)
		state = XBPS_PKG_STATE_INSTALLED;
	else if (strcmp(state_str, "broken") == 0)
		state = XBPS_PKG_STATE_BROKEN;
	else if (strcmp(state_str, "config-files") == 0)
		state = XBPS_PKG_STATE_CONFIG_FILES;
	else if (strcmp(state_str, "not-installed") == 0)
		state = XBPS_PKG_STATE_NOT_INSTALLED;
	else
		return 0;

	return state;
}

int
xbps_get_pkg_state_installed(const char *pkgname, pkg_state_t *state)
{
	prop_dictionary_t dict, pkgd;
	const char *rootdir;
	char *plist;

	assert(pkgname != NULL);
	rootdir = xbps_get_rootdir();
	plist = xbps_xasprintf("%s/%s/%s", rootdir,
	    XBPS_META_PATH, XBPS_REGPKGDB);
	if (plist == NULL)
		return errno;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		free(plist);
		return errno;
	}
	free(plist);

	pkgd = xbps_find_pkg_in_dict(dict, "packages", pkgname);
	if (pkgd == NULL) {
		prop_object_release(dict);
		return ENOENT;
	}
	*state = get_state(pkgd);
	if (*state == 0) {
		prop_object_release(dict);
		return EINVAL;
	}
	prop_object_release(dict);

	return 0;
}

int
xbps_get_pkg_state_dictionary(prop_dictionary_t dict, pkg_state_t *state)
{
	assert(dict != NULL);

	if ((*state = get_state(dict)) == 0)
		return EINVAL;

	return 0;
}

int
xbps_set_pkg_state_dictionary(prop_dictionary_t dict, pkg_state_t state)
{
	assert(dict != NULL);

	return set_new_state(dict, state);
}

int
xbps_set_pkg_state_installed(const char *pkgname, pkg_state_t state)
{
	prop_dictionary_t dict, pkgd;
	prop_array_t array;
	const char *rootdir;
	char *plist;
	int rv = 0;
	bool newpkg = false;

	rootdir = xbps_get_rootdir();
	plist = xbps_xasprintf("%s/%s/%s", rootdir,
	    XBPS_META_PATH, XBPS_REGPKGDB);
	if (plist == NULL)
		return EINVAL;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
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
		pkgd = prop_dictionary_create();
		if (pkgd == NULL) {
			prop_object_release(array);
			rv = errno;
			goto out;
		}
		prop_dictionary_set_cstring_nocopy(pkgd, "pkgname", pkgname);
		if ((rv = set_new_state(pkgd, state)) != 0) {
			prop_object_release(array);
			goto out;
		}
		if (!xbps_add_obj_to_array(array, pkgd)) {
			prop_object_release(array);
			rv = EINVAL;
			goto out;
		}
		if (!xbps_add_obj_to_dict(dict, array, "packages")) {
			prop_object_release(array);
			rv = EINVAL;
			goto out;
		}

	} else {
		pkgd = xbps_find_pkg_in_dict(dict, "packages", pkgname);
		if (pkgd == NULL) {
			newpkg = true;
			pkgd = prop_dictionary_create();
			prop_dictionary_set_cstring_nocopy(pkgd, "pkgname",
			    pkgname);
		}
		array = prop_dictionary_get(dict, "packages");
		if (array == NULL) {
			rv = ENOENT;
			goto out;
		}
		if ((rv = set_new_state(pkgd, state)) != 0) {
			prop_object_release(pkgd);
			goto out;
		}
		if (newpkg && !xbps_add_obj_to_array(array, pkgd)) {
			prop_object_release(pkgd);
			rv = EINVAL;
			goto out;
		}
	}

	if (!prop_dictionary_externalize_to_file(dict, plist))
		rv = errno;

out:
	prop_object_release(dict);
	free(plist);

	return rv;
}
