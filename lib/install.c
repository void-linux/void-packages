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

static int unpack_archive_cb(struct archive *);

int
xbps_install_binary_pkg(const char *pkgname, const char *dest)
{
	prop_dictionary_t repo_dict, pkg_rdict, dict;
	prop_object_t obj;
	const char *repo = "/storage/xbps/binpkgs/pkg-index.plist";
	char dbfile[PATH_MAX], binfile[PATH_MAX];
	int rv = 0;

	assert(pkgname != NULL);
	if (dest) {
		if ((rv = chdir(dest)) != 0)
			return XBPS_PKG_ECHDIRDEST;
	}

	/* Get pkg metadata from a repository */
	repo_dict = prop_dictionary_internalize_from_file(repo);
	pkg_rdict = xbps_find_pkg_in_dict(repo_dict, pkgname);
	if (pkg_rdict == NULL)
		return XBPS_PKG_ENOTINREPO;

	if (!xbps_append_full_path(dbfile, NULL, XBPS_REGPKGDB))
		return EINVAL;

	/* Check if package is already installed. */
	dict = prop_dictionary_internalize_from_file(dbfile);
	if (dict && xbps_find_pkg_in_dict(dict, pkgname))
		return XBPS_PKG_EEXIST;

	/* Looks like it's not, check dependencies and install */
	switch (xbps_check_reqdeps_in_pkg(dbfile, pkg_rdict)) {
	case -1:
		/* There was an error checking pkg deps */
		return XBPS_PKG_EINDEPS;
	case 0:
		/* Package has no deps, just install it */
		obj = prop_dictionary_get(pkg_rdict, "filename");
		strncpy(binfile, "/storage/xbps/binpkgs/", PATH_MAX - 1);
		strncat(binfile, prop_string_cstring_nocopy(obj), PATH_MAX - 1);
		obj = prop_dictionary_get(pkg_rdict, "version");

		printf("=> Installing %s-%s ... ", pkgname,
		    prop_string_cstring_nocopy(obj));

		rv = xbps_unpack_binary_pkg(binfile, unpack_archive_cb);
		break;
	case 1:
		/* Package needs deps */
		break;
	}

	return rv;
}

static int
unpack_archive_cb(struct archive *ar)
{
	struct archive_entry *entry;
	int rv = 0;

	while (archive_read_next_header(ar, &entry) == ARCHIVE_OK) {
		if ((rv = archive_read_extract(ar, entry, 0)) != 0) {
			printf("couldn't write %s (%s), ignoring!\n",
			    archive_entry_pathname(entry), strerror(errno));
		}
	}

	printf("done.\n");
	archive_read_finish(ar);
	return rv;
}

int
xbps_unpack_binary_pkg(const char *filename, int (*cb)(struct archive *))
{
	struct archive *ar;
	int rv;

	assert(filename != NULL);

	ar = archive_read_new();
	if (ar == NULL)
		return ENOMEM;

	/* Enable support for all format and compression methods */
	archive_read_support_compression_all(ar);
	archive_read_support_format_all(ar);

	if ((rv = archive_read_open_filename(ar, filename, 2048)) != 0) {
		archive_read_finish(ar);
		return rv;
	}

	return (*cb)(ar);
}
