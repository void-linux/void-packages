/*-
 * Copyright (c) 2008 Juan Romero Pardines.
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

int
xbps_install_binary_pkg(const char *pkgname, const char *destdir)
{
	prop_array_t array;
	prop_dictionary_t repolistd, repod, pkgrd;
	prop_object_t obj;
	prop_object_iterator_t iter;
	char plist[PATH_MAX];
	int rv = 0;

	assert(pkgname != NULL);
	if (destdir) {
		if ((rv = chdir(destdir)) != 0)
			return XBPS_PKG_ECHDIRDEST;
	}

	/* Get the dictionary with list of repositories. */
	if (!xbps_append_full_path(plist, NULL, XBPS_REPOLIST))
		return EINVAL;

	repolistd = prop_dictionary_internalize_from_file(plist);
	if (repolistd == NULL)
		return EINVAL;

	/* Iterate over the list of repositories to find a pkg. */
	array = prop_dictionary_get(repolistd, "repository-list");
	if (array == NULL || prop_array_count(array) == 0) {
		prop_object_release(repolistd);
		return EINVAL;
	}

	iter = prop_array_iterator(array);
	if (iter == NULL) {
		prop_object_release(repolistd);
		return ENOMEM;
	}

	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		/*
		 * Get the dictionary from a repository's index file.
		 */
		assert(prop_object_type(obj) == PROP_TYPE_STRING);
		memset(plist, 0, sizeof(&plist));
		if (!xbps_append_full_path(plist,
		    prop_string_cstring_nocopy(obj), XBPS_PKGINDEX)) {
			prop_object_iterator_release(iter);
			prop_object_release(repolistd);
			return EINVAL;
		}
		repod = prop_dictionary_internalize_from_file(plist);
		if (repod == NULL) {
			prop_object_iterator_release(iter);
			prop_object_release(repolistd);
			return EINVAL;
		}

		/*
		 * Get the package dictionary from current repository.
		 */
		pkgrd = xbps_find_pkg_in_dict(repod, pkgname);
		if (pkgrd == NULL) {
			prop_object_release(repod);
			continue;
		}

		/*
		 * Check if pkg needs deps.
		 */
		if (!xbps_pkg_has_rundeps(pkgrd)) {
			/* pkg has no deps, just install it. */
			rv = xbps_unpack_binary_pkg(repod, pkgrd,
			    xbps_unpack_archive_cb);
			prop_object_release(repolistd);
			prop_object_release(repod);
			break;
		}

		/*
		 * Install all required dependencies.
		 */
		rv = xbps_install_pkg_deps(array, pkgrd);
		if (rv != 0) {
			prop_object_release(repolistd);
			prop_object_release(repod);
			break;
		}
		/*
		 * Finally install the package, now that all
		 * required dependencies were installed.
		 */
		rv = xbps_unpack_binary_pkg(repod, pkgrd,
		     xbps_unpack_archive_cb);
		prop_object_release(repolistd);
		prop_object_release(repod);
		break;
	}

	prop_object_iterator_release(iter);

	return rv;
}

int
xbps_unpack_archive_cb(struct archive *ar)
{
	struct archive_entry *entry;
	static bool first;
	int rv = 0;

	while (archive_read_next_header(ar, &entry) == ARCHIVE_OK) {
		if ((rv = archive_read_extract(ar, entry, 0)) != 0) {
			if (!first)
				printf("\n");
			first = true;
			printf("couldn't write %s (%s), ignoring!\n",
			    archive_entry_pathname(entry), strerror(errno));
		}
	}

	archive_read_finish(ar);
	return rv;
}

int
xbps_unpack_binary_pkg(prop_dictionary_t repo, prop_dictionary_t pkg,
		       int (*cb)(struct archive *))
{
	prop_string_t pkgname, version, filename, repoloc;
	struct archive *ar;
	char binfile[PATH_MAX];
	int rv;

	assert(pkg != NULL);

	/* Append filename to the full path for binary pkg */
	filename = prop_dictionary_get(pkg, "filename");
	repoloc = prop_dictionary_get(repo, "location-local");

	if (!xbps_append_full_path(binfile,
	    prop_string_cstring_nocopy(repoloc),
	    prop_string_cstring_nocopy(filename)))
		return EINVAL;

	pkgname = prop_dictionary_get(pkg, "pkgname");
	version = prop_dictionary_get(pkg, "version");

	printf("From repository %s ...\n",
	    prop_string_cstring_nocopy(repoloc));
	printf(" Unpacking %s-%s (%s) ... ",
	    prop_string_cstring_nocopy(pkgname),
	    prop_string_cstring_nocopy(version),
	    prop_string_cstring_nocopy(filename));

	(void)fflush(stdout);

	ar = archive_read_new();
	if (ar == NULL)
		return ENOMEM;

	/* Enable support for all format and compression methods */
	archive_read_support_compression_all(ar);
	archive_read_support_format_all(ar);

	if ((rv = archive_read_open_filename(ar, binfile, 2048)) != 0) {
		archive_read_finish(ar);
		return rv;
	}

	if ((rv = (*cb)(ar)) == 0) {
		printf("done.\n");
		(void)fflush(stdout);
	}

	return rv;
}
