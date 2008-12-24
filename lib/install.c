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

bool
xbps_install_binary_pkg_from_repolist(prop_object_t obj, void *arg, bool *done)
{
	prop_dictionary_t dict;
	prop_string_t oloc;
	const char *repofile, *repoloc;
	char plist[PATH_MAX];
	int rv = 0;

	assert(prop_object_type(obj) == PROP_TYPE_STRING);

	/* Get the location */
	repofile = prop_string_cstring_nocopy(obj);

	/* Get string for pkg-index.plist with full path. */
	if (!xbps_append_full_path(plist, repofile, XBPS_PKGINDEX))
		return false;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL || prop_dictionary_count(dict) == 0)
		return false;

	oloc = prop_dictionary_get(dict, "location-remote");
	if (oloc == NULL)
		oloc = prop_dictionary_get(dict, "location-local");

	if (oloc && prop_object_type(oloc) == PROP_TYPE_STRING)
		repoloc = prop_string_cstring_nocopy(oloc);
	else {
		prop_object_release(dict);
		return false;
	}

	printf("Searching in repository: %s\n", repoloc);
	rv = xbps_install_binary_pkg(dict, arg, "/home/juan/root_xbps");
	*done = true;
	prop_object_release(dict);

	if (rv != 0)
		return false;

	return true;
}

int
xbps_install_binary_pkg(prop_dictionary_t repo, const char *pkgname,
			const char *dest)
{
	prop_dictionary_t pkg_rdict, dict;
	prop_object_t obj;
	char dbfile[PATH_MAX];
	int rv = 0;

	assert(pkgname != NULL);
	if (dest) {
		if ((rv = chdir(dest)) != 0)
			return XBPS_PKG_ECHDIRDEST;
	}

	/* Get pkg metadata from a repository */
	pkg_rdict = xbps_find_pkg_in_dict(repo, pkgname);
	if (pkg_rdict == NULL)
		return XBPS_PKG_ENOTINREPO;

	/* Check if package is already installed. */
	if (!xbps_append_full_path(dbfile, NULL, XBPS_REGPKGDB))
		return EINVAL;

	dict = prop_dictionary_internalize_from_file(dbfile);
	if (dict && xbps_find_pkg_in_dict(dict, pkgname)) {
		prop_object_release(dict);
		return XBPS_PKG_EEXIST;
	}

	obj = prop_dictionary_get(pkg_rdict, "version");
	printf("Available package: %s-%s.\n",
	    pkgname, prop_string_cstring_nocopy(obj));
	(void)fflush(stdout);

	/*
	 * Install the package, and its dependencies if there are.
	 */
	switch (xbps_install_pkg_deps(repo, pkg_rdict)) {
	case -1:
		return XBPS_PKG_EINDEPS;
	case 0:
		/*
		 * Package has no dependencies, just install it.
		 */
		rv = xbps_unpack_binary_pkg(pkg_rdict, xbps_unpack_archive_cb);
		break;
	case 1:
		/*
		 * 1 means that package has dependencies, but
		 * xbps_install_pkg_deps() takes care of it.
		 */
		break;
	}

	return rv;
}

int
xbps_unpack_archive_cb(struct archive *ar)
{
	struct archive_entry *entry;
	int rv = 0;

	while (archive_read_next_header(ar, &entry) == ARCHIVE_OK) {
		if ((rv = archive_read_extract(ar, entry, 0)) != 0) {
			printf("couldn't write %s (%s), ignoring!\n",
			    archive_entry_pathname(entry), strerror(errno));
		}
	}

	archive_read_finish(ar);
	return rv;
}

int
xbps_unpack_binary_pkg(prop_dictionary_t pkg, int (*cb)(struct archive *))
{
	prop_string_t pkgname, version, filename;
	struct archive *ar;
	char binfile[PATH_MAX];
	int rv;

	assert(pkg != NULL);

	/* Append filename to the full path for binary pkg */
	filename = prop_dictionary_get(pkg, "filename");
	if (!xbps_append_full_path(binfile, "/storage/xbps/binpkgs",
	    prop_string_cstring_nocopy(filename)))
		return EINVAL;

	pkgname = prop_dictionary_get(pkg, "pkgname");
	version = prop_dictionary_get(pkg, "version");

	printf("Unpacking %s-%s (from %s)... ",
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

	if ((rv = (*cb)(ar)) == 0)
		printf("done.\n");

	return rv;
}
