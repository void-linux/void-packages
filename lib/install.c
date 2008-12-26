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
xbps_install_binary_pkg_from_repolist(prop_object_t obj, void *arg,
				      bool *loop_done)
{
	prop_dictionary_t repod, pkgrd;
	const char *pkgname = arg, *version, *desc;
	char plist[PATH_MAX];
	int rv = 0;

	/*
	 * Get the dictionary from a repository's index file.
	 */
	memset(plist, 0, sizeof(&plist));
	if (!xbps_append_full_path(plist,
	    prop_string_cstring_nocopy(obj), XBPS_PKGINDEX))
		return EINVAL;

	repod = prop_dictionary_internalize_from_file(plist);
	if (repod == NULL)
		return EINVAL;

	/*
	 * Get the package dictionary from current repository.
	 */
	pkgrd = xbps_find_pkg_in_dict(repod, pkgname);
	if (pkgrd == NULL) {
		prop_object_release(repod);
		return XBPS_PKG_ENOTINREPO;
	}

	prop_dictionary_get_cstring_nocopy(pkgrd, "version", &version);
	prop_dictionary_get_cstring_nocopy(pkgrd, "short_desc", &desc);
	assert(version != NULL);
	assert(desc != NULL);

	/*
	 * Check if this package needs dependencies.
	 */
	if (!xbps_pkg_has_rundeps(pkgrd)) {
		/* pkg has no deps, just install it. */
		rv = xbps_unpack_binary_pkg(repod, pkgrd,
		    xbps_unpack_archive_cb);
		if (rv == 0) {
			rv = xbps_register_pkg(pkgname, version, desc);
			if (rv == EEXIST)
				rv = 0;
		}
		prop_object_release(repod);
		*loop_done = true;
		return rv;
	}

	/*
	 * Install all required dependencies.
	 */
	rv = xbps_install_pkg_deps(pkgrd);
	if (rv != 0) {
		prop_object_release(repod);
		return rv;
	}
	/*
	 * Finally install the package, now that all
	 * required dependencies were installed.
	 */
	rv = xbps_unpack_binary_pkg(repod, pkgrd, xbps_unpack_archive_cb);
	if (rv == 0) {
		rv = xbps_register_pkg(pkgname, version, desc);
		if (rv == EEXIST)
			rv = 0;
	}
	prop_object_release(repod);
	*loop_done = true;

	return rv;
}

int
xbps_install_binary_pkg(const char *pkgname, const char *destdir)
{
	prop_dictionary_t repolistd;
	char plist[PATH_MAX];
	int rv = 0;

	assert(pkgname != NULL);
	if (destdir) {
		if ((rv = chdir(destdir)) != 0)
			return XBPS_PKG_ECHDIRDEST;
	}

	/*
	 * Get the dictionary with the list of registered
	 * repositories.
	 */
	if (!xbps_append_full_path(plist, NULL, XBPS_REPOLIST))
		return EINVAL;

	repolistd = prop_dictionary_internalize_from_file(plist);
	if (repolistd == NULL)
		return EINVAL;

	/*
	 * Iterate over the repositories to find the binary packages
	 * required by this package.
	 */
	rv = xbps_callback_array_iter_in_dict(repolistd, "repository-list",
	    xbps_install_binary_pkg_from_repolist, (void *)pkgname);
	prop_object_release(repolistd);

	return rv;
}

static prop_dictionary_t
make_dict_from_pkg(const char *name, const char *ver, const char *desc)
{
	prop_dictionary_t dict;

	dict = prop_dictionary_create();
	assert(dict != NULL);

	prop_dictionary_set_cstring_nocopy(dict, "pkgname", name);
	prop_dictionary_set_cstring_nocopy(dict, "version", ver);
	prop_dictionary_set_cstring_nocopy(dict, "short_desc", desc);

	return dict;
}

int
xbps_register_pkg(const char *pkgname, const char *version, const char *desc)
{
	prop_dictionary_t dict, pkgd;
	prop_array_t array;
	char plist[PATH_MAX];
	int rv = 0;

	assert(pkgname != NULL);
	assert(version != NULL);
	assert(desc != NULL);

	if (!xbps_append_full_path(plist, NULL, XBPS_REGPKGDB))
		return EINVAL;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		/* No packages registered yet. */
		dict = prop_dictionary_create();
		if (dict == NULL)
			return ENOMEM;

		array = prop_array_create();
		if (array == NULL) {
			prop_object_release(dict);
			return ENOMEM;
		}

		pkgd = make_dict_from_pkg(pkgname, version, desc);

		if (!xbps_add_obj_to_array(array, pkgd)) {
			prop_object_release(array);
			prop_object_release(dict);
			prop_object_release(pkgd);
			return EINVAL;
		}

		if (!xbps_add_obj_to_dict(dict, array, "packages")) {
			prop_object_release(array);
			prop_object_release(dict);
			return EINVAL;
		}

	} else {
		/* Check if package is already registered. */
		pkgd = xbps_find_pkg_in_dict(dict, pkgname);
		if (pkgd != NULL) {
			prop_object_release(dict);
			return EEXIST;
		}

		pkgd = make_dict_from_pkg(pkgname, version, desc);
		array = prop_dictionary_get(dict, "packages");
		assert(array != NULL);

		if (!xbps_add_obj_to_array(array, pkgd)) {
			prop_object_release(pkgd);
			prop_object_release(dict);
			return EINVAL;
		}
	}


	if (!prop_dictionary_externalize_to_file(dict, plist))
		rv = errno;

	prop_object_release(dict);

	return rv;
}

/*
 * Flags for extracting files in binary packages.
 */
#define EXTRACT_FLAGS	ARCHIVE_EXTRACT_OWNER | ARCHIVE_EXTRACT_PERM | \
			ARCHIVE_EXTRACT_TIME | \
			ARCHIVE_EXTRACT_SECURE_NODOTDOT | \
			ARCHIVE_EXTRACT_SECURE_SYMLINKS | \
			ARCHIVE_EXTRACT_UNLINK

int
xbps_unpack_archive_cb(struct archive *ar)
{
	struct archive_entry *entry;
	int rv = 0, flags;

	if (geteuid() == 0)
		flags = EXTRACT_FLAGS;
	else
		flags = 0;

	while (archive_read_next_header(ar, &entry) == ARCHIVE_OK) {
		if ((rv = archive_read_extract(ar, entry, flags)) != 0) {
			printf("\ncouldn't unpack %s (%s), exiting!\n",
			    archive_entry_pathname(entry), strerror(errno));
			break;
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
