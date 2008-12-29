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
#include <unistd.h>
#include <fcntl.h>

#include <xbps_api.h>

static const char *chroot_dir;

int
xbps_install_binary_pkg_from_repolist(prop_object_t obj, void *arg,
				      bool *loop_done)
{
	prop_dictionary_t repod, pkgrd;
	const char *pkgname = arg, *version, *desc;
	char *plist;
	int rv = 0;

	/*
	 * Get the dictionary from a repository's index file.
	 */
	plist = xbps_append_full_path(false,
	    prop_string_cstring_nocopy(obj), XBPS_PKGINDEX);
	if (plist == NULL)
		return EINVAL;

	repod = prop_dictionary_internalize_from_file(plist);
	if (repod == NULL) {
		free(plist);
		return EINVAL;
	}

	/*
	 * Get the package dictionary from current repository.
	 */
	pkgrd = xbps_find_pkg_in_dict(repod, pkgname);
	if (pkgrd == NULL) {
		free(plist);
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
		free(plist);
		prop_object_release(repod);
		*loop_done = true;
		return rv;
	}

	/*
	 * Install all required dependencies.
	 */
	rv = xbps_install_pkg_deps(pkgrd);
	if (rv != 0) {
		free(plist);
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
	free(plist);
	prop_object_release(repod);
	*loop_done = true;

	return rv;
}

int
xbps_install_binary_pkg(const char *pkgname, const char *destdir)
{
	prop_dictionary_t repolistd;
	char *plist;
	int rv = 0;

	assert(pkgname != NULL);
	if (destdir) {
		if ((rv = chdir(destdir)) != 0)
			return errno;
		chroot_dir = destdir;
	} else
		chroot_dir = "NOTSET";

	/*
	 * Get the dictionary with the list of registered
	 * repositories.
	 */
	plist = xbps_append_full_path(true, NULL, XBPS_REPOLIST);
	if (plist == NULL)
		return EINVAL;

	repolistd = prop_dictionary_internalize_from_file(plist);
	if (repolistd == NULL) {
		free(plist);
		return EINVAL;
	}

	/*
	 * Iterate over the repositories to find the binary packages
	 * required by this package.
	 */
	rv = xbps_callback_array_iter_in_dict(repolistd, "repository-list",
	    xbps_install_binary_pkg_from_repolist, (void *)pkgname);

	free(plist);
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
	char *plist;
	int rv = 0;

	assert(pkgname != NULL);
	assert(version != NULL);
	assert(desc != NULL);

	plist = xbps_append_full_path(true, NULL, XBPS_REGPKGDB);
	if (plist == NULL)
		return EINVAL;

	dict = prop_dictionary_internalize_from_file(plist);
	if (dict == NULL) {
		/* No packages registered yet. */
		dict = prop_dictionary_create();
		if (dict == NULL) {
			free(plist);
			return ENOMEM;
		}

		array = prop_array_create();
		if (array == NULL) {
			free(plist);
			prop_object_release(dict);
			return ENOMEM;
		}

		pkgd = make_dict_from_pkg(pkgname, version, desc);

		if (!xbps_add_obj_to_array(array, pkgd)) {
			prop_object_release(array);
			prop_object_release(dict);
			prop_object_release(pkgd);
			free(plist);
			return EINVAL;
		}

		if (!xbps_add_obj_to_dict(dict, array, "packages")) {
			prop_object_release(array);
			prop_object_release(dict);
			free(plist);
			return EINVAL;
		}

	} else {
		/* Check if package is already registered. */
		pkgd = xbps_find_pkg_in_dict(dict, pkgname);
		if (pkgd != NULL) {
			prop_object_release(dict);
			free(plist);
			return EEXIST;
		}

		pkgd = make_dict_from_pkg(pkgname, version, desc);
		array = prop_dictionary_get(dict, "packages");
		assert(array != NULL);

		if (!xbps_add_obj_to_array(array, pkgd)) {
			prop_object_release(pkgd);
			prop_object_release(dict);
			free(plist);
			return EINVAL;
		}
	}


	if (!prop_dictionary_externalize_to_file(dict, plist))
		rv = errno;

	prop_object_release(dict);
	free(plist);

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
xbps_unpack_archive_cb(struct archive *ar, prop_dictionary_t pkg)
{
	struct archive_entry *entry;
	size_t len;
	const char *prepost = "./XBPS_PREPOST_ACTION";
	const char *pkgname, *version;
	char *buf;
	int rv = 0;
	bool actgt = false;

	assert(ar != NULL);
	assert(pkg != NULL);

	prop_dictionary_get_cstring_nocopy(pkg, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(pkg, "version", &version);

	/*
	 * This length is '.%s/metadata/%s/prepost-action.sh' not
	 * including nul.
	 */
	len = strlen(XBPS_META_PATH) + strlen(pkgname) + 26;
	buf = malloc(len + 1);
	if (buf == NULL)
		return ENOMEM;

	if (snprintf(buf, len + 1, ".%s/metadata/%s/prepost-action",
	    XBPS_META_PATH, pkgname) < 0) {
		free(buf);
		return -1;
	}

	while (archive_read_next_header(ar, &entry) == ARCHIVE_OK) {
		/*
		 * Run the pre installation action target if there's a script
		 * before writing data to disk.
		 */
		if (strcmp(prepost, archive_entry_pathname(entry)) == 0) {
			actgt = true;

			archive_entry_set_pathname(entry, buf);

			if ((rv = archive_read_extract(ar, entry,
			     EXTRACT_FLAGS)) != 0)
				break;

			if ((rv = xbps_file_exec(buf, chroot_dir, "preinst",
			     pkgname, version, NULL)) != 0) {
				printf("%s: preinst action target error %s\n",
				    pkgname, strerror(errno));
				(void)fflush(stdout);
				break;
			}

			/* pass to the next entry if successful */
			continue;
		}
		/*
		 * Extract all data from the archive now.
		 */
		if ((rv = archive_read_extract(ar, entry,
		     EXTRACT_FLAGS)) != 0) {
			printf("\ncouldn't unpack %s (%s), exiting!\n",
			    archive_entry_pathname(entry), strerror(errno));
			(void)fflush(stdout);
			break;
		}
	}

	if (rv == 0 && actgt) {
		/*
		 * Run the post installaction action target, if package
		 * contains the script.
		 */
		if ((rv = xbps_file_exec(buf, chroot_dir, "postinst",
		     pkgname, version, NULL)) != 0) {
			printf("%s: postinst action target error %s\n",
			    pkgname, strerror(errno));
			(void)fflush(stdout);
		}
	}

	free(buf);

	return rv;
}

int
xbps_unpack_binary_pkg(prop_dictionary_t repo, prop_dictionary_t pkg,
		       int (*cb)(struct archive *, prop_dictionary_t))
{
	prop_string_t pkgname, version, filename, repoloc;
	struct archive *ar;
	char *binfile;
	int pkg_fd, rv;

	assert(pkg != NULL);
	assert(repo != NULL);
	assert(cb != NULL);

	/* Append filename to the full path for binary pkg */
	filename = prop_dictionary_get(pkg, "filename");
	repoloc = prop_dictionary_get(repo, "location-local");

	binfile= xbps_append_full_path(false,
	    prop_string_cstring_nocopy(repoloc),
	    prop_string_cstring_nocopy(filename));
	if (binfile == NULL)
		return EINVAL;

	if ((pkg_fd = open(binfile, O_RDONLY)) == -1) {
		free(binfile);
		return errno;
	}

	pkgname = prop_dictionary_get(pkg, "pkgname");
	version = prop_dictionary_get(pkg, "version");

	printf("Installing %s-%s (%s) ...\n",
	    prop_string_cstring_nocopy(pkgname),
	    prop_string_cstring_nocopy(version),
	    prop_string_cstring_nocopy(filename));

	(void)fflush(stdout);

	ar = archive_read_new();
	if (ar == NULL) {
		free(binfile);
		close(pkg_fd);
		return ENOMEM;
	}

	/* Enable support for all format and compression methods */
	archive_read_support_compression_all(ar);
	archive_read_support_format_all(ar);

	if ((rv = archive_read_open_fd(ar, pkg_fd, 2048)) != 0) {
		archive_read_finish(ar);
		free(binfile);
		close(pkg_fd);
		return rv;
	}

	rv = (*cb)(ar, pkg);
	/*
	 * If installation of package was successful, make sure the package
	 * is really on storage (if possible).
	 */
	if (rv == 0)
		if ((rv = fdatasync(pkg_fd)) == -1)
			rv = errno;

	archive_read_finish(ar);
	close(pkg_fd);
	free(binfile);

	return rv;
}
