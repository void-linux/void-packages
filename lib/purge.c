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
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <dirent.h>

#include <xbps_api.h>

static int	remove_pkg_metadata(const char *);

/*
 * Purge a package that is currently in "config-files" state.
 * This removes configuration files if they weren't modified,
 * removes metadata files and fully unregisters the package.
 */
int
xbps_purge_pkg(const char *pkgname)
{
	prop_dictionary_t dict;
	prop_array_t array;
	prop_object_t obj;
	prop_object_iterator_t iter;
	const char *rootdir, *file, *sha256;
	char *path;
	int rv = 0, flags;
	pkg_state_t state = 0;

	assert(pkgname != NULL);
	rootdir = xbps_get_rootdir();
	flags = xbps_get_flags();

	/*
	 * Skip packages that aren't in "config-files" state.
	 */
	if ((rv = xbps_get_pkg_state_installed(pkgname, &state)) != 0)
		return rv;

	if (state != XBPS_PKG_STATE_CONFIG_FILES)
		return 0;

	/*
	 * Iterate over the pkg file list dictionary and remove all
	 * unmodified configuration files.
	 */
	path = xbps_xasprintf("%s/%s/metadata/%s/%s",
	    rootdir, XBPS_META_PATH, pkgname, XBPS_PKGFILES);
	if (path == NULL)
                return errno;

	dict = prop_dictionary_internalize_from_file(path);
	if (dict == NULL) {
		free(path);
		return errno;
	}
	free(path);

	array = prop_dictionary_get(dict, "conf_files");
	if (array == NULL) {
		goto out;
	} else if (prop_object_type(array) != PROP_TYPE_ARRAY) {
		prop_object_release(dict);
		return EINVAL;
	} else if (prop_array_count(array) == 0) {
		goto out;
	}

	iter = xbps_get_array_iter_from_dict(dict, "conf_files");
	if (iter == NULL)
		return EINVAL;

	while ((obj = prop_object_iterator_next(iter))) {
		if (!prop_dictionary_get_cstring_nocopy(obj, "file", &file)) {
			prop_object_iterator_release(iter);
			prop_object_release(dict);
			return EINVAL;
		}
		path = xbps_xasprintf("%s/%s", rootdir, file);
		if (path == NULL) {
			prop_object_iterator_release(iter);
			prop_object_release(dict);
			return EINVAL;
		}
		prop_dictionary_get_cstring_nocopy(obj, "sha256", &sha256);
		rv = xbps_check_file_hash(path, sha256);
		if (rv == ENOENT) {
			printf("Configuration file %s doesn't exist!\n", file);
			free(path);
			continue;
		} else if (rv == ERANGE) {
			if (flags & XBPS_FLAG_VERBOSE)
				printf("Configuration file %s has been "
				    "modified, preserving...\n", file);

			free(path);
			continue;
		} else if (rv != 0 && rv != ERANGE) {
			free(path);
			prop_object_iterator_release(iter);
			prop_object_release(dict);
			return rv;
		}
		if ((rv = remove(path)) == -1) {
			if (flags & XBPS_FLAG_VERBOSE)
				printf("WARNING: can't remove %s (%s)\n",
				    file, strerror(errno));

			free(path);
			continue;
		}
		if (flags & XBPS_FLAG_VERBOSE)
			printf("Removed configuration file %s\n", file);

		free(path);
	}

	prop_object_iterator_release(iter);
out:
	prop_object_release(dict);

	if ((rv = remove_pkg_metadata(pkgname)) == 0) {
		if ((rv = xbps_unregister_pkg(pkgname)) == 0)
			printf("Package %s has been purged successfully.\n",
			    pkgname);
	}

	return rv;
}

static int
remove_pkg_metadata(const char *pkgname)
{
	struct dirent *dp;
	DIR *dirp;
	const char *rootdir;
	char *metadir, *path;
	int flags = 0, rv = 0;

	assert(pkgname != NULL);

	rootdir = xbps_get_rootdir();
	flags = xbps_get_flags();

	metadir = xbps_xasprintf("%s/%s/metadata/%s", rootdir,
	     XBPS_META_PATH, pkgname);
	if (metadir == NULL)
		return errno;

	dirp = opendir(metadir);
	if (dirp == NULL) {
		free(metadir);
		return errno;
	}

	while ((dp = readdir(dirp)) != NULL) {
		if ((strcmp(dp->d_name, ".") == 0) ||
		    (strcmp(dp->d_name, "..") == 0))
			continue;

		path = xbps_xasprintf("%s/%s", metadir, dp->d_name);
		if (path == NULL) {
			(void)closedir(dirp);
			free(metadir);
			return -1;
		}

		if ((rv = unlink(path)) == -1) {
			if (flags & XBPS_FLAG_VERBOSE)
				printf("WARNING: can't remove %s (%s)\n",
				    pkgname, strerror(errno));
		}
		free(path);
	}
	(void)closedir(dirp);
	rv = rmdir(metadir);
	free(metadir);

	return rv;
}
