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
#include <dirent.h>
#include <sys/stat.h>
#include <sys/utsname.h>

#include <xbps_api.h>
#include "index.h"

/* Array of valid architectures */
const char *archdirs[] = { "i686", "x86_64", "noarch", NULL };

static prop_dictionary_t
repoidx_getdict(const char *pkgdir)
{
	prop_dictionary_t dict;
	prop_array_t array;
	char *plist;

	plist = xbps_get_pkg_index_plist(pkgdir);
	if (plist == NULL)
		return NULL;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		dict = prop_dictionary_create();
		if (dict == NULL) {
			free(plist);
			return NULL;
		}

		array = prop_array_create();
		if (array == NULL) {
			free(plist);
			prop_object_release(dict);
			return NULL;
		}

		prop_dictionary_set(dict, "packages", array);
		prop_object_release(array);
		prop_dictionary_set_cstring_nocopy(dict,
		    "location-local", pkgdir);
		prop_dictionary_set_cstring_nocopy(dict,
		    "pkgindex-version", XBPS_PKGINDEX_VERSION);
	}
	free(plist);

	return dict;
}

static int
repoidx_addpkg(const char *file, const char *filename, const char *pkgdir)
{
	prop_dictionary_t newpkgd, idxdict, curpkgd;
	prop_array_t pkgar;
	struct archive *ar;
	struct archive_entry *entry;
	struct stat st;
	ssize_t nbytes = -1;
	const char *pkgname, *version, *regver;
	char *props, *sha256, *plist;
	size_t propslen = 0;
	int rv = 0;

	ar = archive_read_new();
	if (ar == NULL)
		return errno;

	/* Enable support for all format and compression methods */
	archive_read_support_compression_all(ar);
	archive_read_support_format_all(ar);

	if ((rv = archive_read_open_filename(ar, file, 2048)) == -1) {
		archive_read_finish(ar);
		return errno;
	}

	/* Get existing or create repo index dictionary */
	idxdict = repoidx_getdict(pkgdir);
	if (idxdict == NULL) {
		archive_read_finish(ar);
		return errno;
	}
	plist = xbps_get_pkg_index_plist(pkgdir);
	if (plist == NULL) {
		prop_dictionary_remove(idxdict, "packages");
		prop_object_release(idxdict);
		archive_read_finish(ar);
		return ENOMEM;
	}

	/*
	 * Open the binary package and read the props.plist
	 * into a buffer.
	 */
	while (archive_read_next_header(ar, &entry) == ARCHIVE_OK) {
		if (strstr(archive_entry_pathname(entry), "props.plist") == 0) {
			archive_read_data_skip(ar);
			continue;
		}

		propslen = archive_entry_size(entry);
		props = malloc(propslen);
		if (props == NULL) {
			rv = errno;
			break;
		}
		nbytes = archive_read_data(ar, props, propslen);
		if ((size_t)nbytes != propslen) {
			rv = EINVAL;
			break;
		}
		newpkgd = prop_dictionary_internalize(props);
		free(props);
		propslen = 0;
		if (newpkgd == NULL) {
			archive_read_data_skip(ar);
			continue;
		} else if (prop_object_type(newpkgd) != PROP_TYPE_DICTIONARY) {
			prop_object_release(newpkgd);
			archive_read_data_skip(ar);
			continue;
		}

		prop_dictionary_get_cstring_nocopy(newpkgd, "pkgname",
		    &pkgname);
		prop_dictionary_get_cstring_nocopy(newpkgd, "version",
		    &version);
		/*
		 * Check if this package exists already in the index, but first
		 * checking the version. If current package version is greater
		 * than current registered package, update the index; otherwise
		 * pass to the next one.
		 */
		curpkgd = xbps_find_pkg_in_dict(idxdict, "packages", pkgname);
		if (curpkgd) {
			prop_dictionary_get_cstring_nocopy(curpkgd,
			    "version", &regver);
			if (xbps_cmpver_versions(version, regver) <= 0) {
				printf("Skipping %s. Version %s already "
				    "registered.\n", filename, regver);
				prop_object_release(newpkgd);
				archive_read_data_skip(ar);
				break;
			}
			/*
			 * Current package is newer than the one that is
			 * registered actually, remove old package from
			 * the index.
			 */
			if (!xbps_remove_pkg_from_dict(idxdict,
			    "packages", pkgname)) {
				prop_object_release(newpkgd);
				rv = EINVAL;
				break;
			}
		}

		/*
		 * We have the dictionary now, add the required
		 * objects for the index.
		 */
		prop_dictionary_set_cstring_nocopy(newpkgd, "filename",
		    filename);
		sha256 = xbps_get_file_hash(file);
		if (sha256 == NULL) {
			prop_object_release(newpkgd);
			rv = errno;
			break;
		}
		prop_dictionary_set_cstring(newpkgd, "filename-sha256",
		    sha256);
		free(sha256);

		if (stat(file, &st) == -1) {
			prop_object_release(newpkgd);
			rv = errno;
			break;
		}
		prop_dictionary_set_uint64(newpkgd, "filename-size",
		    st.st_size);
		/*
		 * Add dictionary into the index and update package count.
		 */
		pkgar = prop_dictionary_get(idxdict, "packages");
		if (pkgar == NULL) {
			prop_object_release(newpkgd);
			rv = errno;
			break;
		}
		if (!xbps_add_obj_to_array(pkgar, newpkgd)) {
			prop_object_release(newpkgd);
			rv = EINVAL;
			break;
		}

		prop_dictionary_set_uint64(idxdict, "total-pkgs",
		    prop_array_count(pkgar));
		if (!prop_dictionary_externalize_to_file(idxdict, plist)) {
			rv = errno;
			break;
		}
		printf("Registered %s-%s in package index.\n",
		    pkgname, version);
		break;
	}
	archive_read_finish(ar);
	free(plist);
	prop_object_release(idxdict);

	return rv;
}

int
xbps_repo_genindex(const char *pkgdir)
{
	struct dirent *dp;
	DIR *dirp;
	struct utsname un;
	char *binfile, *path;
	size_t i;
	int rv = 0;
	bool foundpkg = false;

	if (uname(&un) == -1)
		return errno;

	/*
	 * Iterate over the known architecture directories to find
	 * binary packages.
	 */
	for (i = 0; archdirs[i] != NULL; i++) {
		if ((strcmp(archdirs[i], un.machine)) &&
		    (strcmp(archdirs[i], "noarch")))
			continue;

		path = xbps_append_full_path(false, pkgdir, archdirs[i]);
		if (path == NULL)
			return errno;

		dirp = opendir(path);
		if (dirp == NULL) {
			free(path);
			continue;
		}

		while ((dp = readdir(dirp)) != NULL) {
			if ((strcmp(dp->d_name, ".") == 0) ||
			    (strcmp(dp->d_name, "..") == 0))
				continue;

			/* Ignore unknown files */
			if (strstr(dp->d_name, ".xbps") == NULL)
				continue;

			foundpkg = true;
			binfile = xbps_append_full_path(false, path,
			    dp->d_name);
			if (binfile == NULL) {
				(void)closedir(dirp);
				free(path);
				return errno;
			}
			rv = repoidx_addpkg(binfile, dp->d_name, pkgdir);
			free(binfile);
			if (rv != 0) {
				(void)closedir(dirp);
				free(path);
				return rv;
			}

		}
		(void)closedir(dirp);
		free(path);
	}

	if (foundpkg == false)
		rv = ENOENT;

	return rv;
}
