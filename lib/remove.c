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
#include <limits.h>
#include <unistd.h>
#include <fcntl.h>
#include <ctype.h>
#include <dirent.h>

#include <xbps_api.h>

struct rm_cbarg {
	const char *destdir;
	int flags;
};

static int	remove_pkg_files(prop_object_t, void *, bool *);

int
xbps_unregister_pkg(const char *pkgname)
{
	char *plist;
	int rv = 0;

	assert(pkgname != NULL);

	plist = xbps_append_full_path(true, NULL, XBPS_REGPKGDB);
	if (plist == NULL)
		return EINVAL;

	if (!xbps_remove_pkg_dict_from_file(pkgname, plist))
		rv = errno;
	
	free(plist);

	return rv;
}

static int
xbps_remove_binary_pkg_meta(const char *pkgname, const char *destdir, int flags)
{
	struct dirent *dp;
	DIR *dirp;
	char metadir[PATH_MAX - 1], path[PATH_MAX - 1];
	int rv = 0;

	assert(pkgname != NULL);

	if (destdir == NULL)
		destdir = "";

	(void)snprintf(metadir, sizeof(metadir), "%s%s/metadata/%s",
	    destdir, XBPS_META_PATH, pkgname);

	dirp = opendir(metadir);
	if (dirp == NULL)
		return errno;

	while ((dp = readdir(dirp)) != NULL) {
		if ((strcmp(dp->d_name, ".") == 0) ||
		    (strcmp(dp->d_name, "..") == 0))
			continue;

		if (snprintf(path, sizeof(path), "%s%s/metadata/%s/%s",
		    destdir, XBPS_META_PATH, pkgname, dp->d_name) < 0) {
			(void)closedir(dirp);
			return -1;
		}

		if ((rv = unlink(path)) == -1) {
			if (flags & XBPS_UNPACK_VERBOSE)
				printf("WARNING: can't remove %s (%s)\n",
				    pkgname, strerror(errno));
		}
		(void)memset(&path, 0, sizeof(path));
	}
	(void)closedir(dirp);
	rv = rmdir(metadir);

	return rv;
}

static int
remove_pkg_files(prop_object_t obj, void *arg, bool *loop_done)
{
	struct rm_cbarg *rmcb = arg;
	const char *file = NULL, *sha256;
	char *path = NULL;
	int rv = 0;

	(void)loop_done;

	prop_dictionary_get_cstring_nocopy(obj, "file", &file);
	if (file != NULL) {
		path = xbps_append_full_path(false, rmcb->destdir, file);
		if (path == NULL)
			return EINVAL;

		prop_dictionary_get_cstring_nocopy(obj, "sha256", &sha256);
		if ((rv = xbps_check_file_hash(path, sha256)) == ERANGE) {
			if (rmcb->flags & XBPS_UNPACK_VERBOSE)
				printf("WARNING: SHA256 doesn't match for "
				    "file %s, ignoring...\n", file);
			goto out;
		}

		if ((rv = unlink(path)) == -1) {
			if (rmcb->flags & XBPS_UNPACK_VERBOSE)
				printf("WARNING: can't remove file %s (%s)\n",
				    file, strerror(errno));
			goto out;
		}
		if (rmcb->flags & XBPS_UNPACK_VERBOSE)
			printf("Removed file: %s\n", file);

		goto out;
	}

	prop_dictionary_get_cstring_nocopy(obj, "dir", &file);
	if (file != NULL) {
		path = xbps_append_full_path(false, rmcb->destdir, file);
		if (path == NULL)
			return EINVAL;

		if ((rv = rmdir(path)) == -1) {
			if (errno == ENOTEMPTY)
				goto out;

			if (rmcb->flags & XBPS_UNPACK_VERBOSE) {
				printf("WARNING: can't remove "
				    "directory %s (%s)\n", file,
				    strerror(errno));
				goto out;
			}
			if (rmcb->flags & XBPS_UNPACK_VERBOSE)
				printf("Removed directory: %s\n", file);
		}
	}
out:
	free(path);

	return 0;
}

int
xbps_remove_binary_pkg(const char *pkgname, const char *destdir, int flags)
{
	prop_dictionary_t fdict;
	struct rm_cbarg rmcbarg;
	char path[PATH_MAX - 1], *buf;
	int fd, rv = 0;
	size_t len = 0;
	bool prepostf = false;

	assert(pkgname != NULL);

	if (destdir == NULL)
		destdir = "";

	/* Check if pkg is installed */
	if (xbps_check_is_installed_pkgname(pkgname) == false)
		return ENOENT;

	/*
	 * This length is '%s%s/metadata/%s/REMOVE' + NULL.
	 */
	len = strlen(XBPS_META_PATH) + strlen(destdir) + strlen(pkgname) + 19;
	buf = malloc(len);
	if (buf == NULL)
		return errno;

	if (snprintf(buf, len, "%s%s/metadata/%s/REMOVE",
	    destdir, XBPS_META_PATH, pkgname) < 0) {
		free(buf);
		return -1;
	}

	/* Find out if the REMOVE file exists */
	if ((fd = open(buf, O_RDONLY)) == -1) {
		if (errno != ENOENT) {
			free(buf);
			return errno;
		}
	} else {
		/* Run the preremove action */
		(void)close(fd);
		prepostf = true;
		if ((rv = xbps_file_exec(buf, destdir, "pre", pkgname,
		     NULL)) != 0) {
			printf("%s: prerm action target error (%s)\n", pkgname,
			    strerror(errno));
			free(buf);
			return rv;
		}
	}

	/*
	 * Iterate over the pkg file list dictionary and remove all
	 * files/dirs associated.
	 */
	(void)snprintf(path, sizeof(path), "%s%s/metadata/%s/files.plist",
	    destdir, XBPS_META_PATH, pkgname);

	fdict = prop_dictionary_internalize_from_file(path);
	if (fdict == NULL) {
		free(buf);
		return errno;
	}

	rmcbarg.destdir = destdir;
	rmcbarg.flags = flags;

	rv = xbps_callback_array_iter_in_dict(fdict, "filelist",
	    remove_pkg_files, (void *)&rmcbarg);
	if (rv != 0) {
		free(buf);
		prop_object_release(fdict);
		return rv;
	}
	prop_object_release(fdict);

	/* If successful, unregister pkg from db */
	if (((rv = xbps_unregister_pkg(pkgname)) == 0) && prepostf) {
		/* Run the postremove action target */
		if ((rv = xbps_file_exec(buf, destdir, "post",
		     pkgname, NULL)) != 0) {
			printf("%s: postrm action target error (%s)\n",
			    pkgname, strerror(errno));
			free(buf);
			return rv;
		}
	}

	free(buf);
	rv = xbps_remove_binary_pkg_meta(pkgname, destdir, flags);

	return rv;
}
