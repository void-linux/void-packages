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

static int	remove_pkg_files(prop_object_t, void *, bool *);

int
xbps_unregister_pkg(const char *pkgname)
{
	const char *rootdir;
	char *plist;
	int rv = 0;

	assert(pkgname != NULL);

	rootdir = xbps_get_rootdir();
	plist = xbps_xasprintf("%s/%s/%s", rootdir,
	     XBPS_META_PATH, XBPS_REGPKGDB);
	if (plist == NULL)
		return EINVAL;

	if (!xbps_remove_pkg_dict_from_file(pkgname, plist))
		rv = errno;
	
	free(plist);

	return rv;
}

static int
xbps_remove_binary_pkg_meta(const char *pkgname)
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
	if (dirp == NULL)
		return errno;

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
			if (flags & XBPS_VERBOSE)
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

static int
remove_pkg_files(prop_object_t obj, void *arg, bool *loop_done)
{
	prop_bool_t bobj;
	const char *file, *rootdir, *sha256, *type;
	char *path = NULL;
	int flags = 0, rv = 0;

	(void)arg;
	(void)loop_done;

	rootdir = xbps_get_rootdir();
	flags = xbps_get_flags();

	if (!prop_dictionary_get_cstring_nocopy(obj, "file", &file))
		return EINVAL;

	path = xbps_xasprintf("%s/%s", rootdir, file);
	if (path == NULL)
		return EINVAL;

	if (!prop_dictionary_get_cstring_nocopy(obj, "type", &type)) {
		free(path);
		return EINVAL;
	}

	if (strcmp(type, "file") == 0) {
		prop_dictionary_get_cstring_nocopy(obj, "sha256", &sha256);
		rv = xbps_check_file_hash(path, sha256);
		if (rv != 0 && rv != ERANGE) {
			free(path);
			return rv;
		}

		bobj = prop_dictionary_get(obj, "conf_file");
		if (bobj != NULL) {
			/*
			 * If hash is the same than the one provided by
			 * package, that means the file hasn't been changed
			 * and therefore can be removed. Otherwise keep it.
			 */
			if (rv == ERANGE)
				goto out;
		}

		if (rv == ERANGE) {
			if (flags & XBPS_VERBOSE)
				printf("WARNING: SHA256 doesn't match for "
				    "file %s, ignoring...\n", file);
			goto out;
		}

		if ((rv = remove(path)) == -1) {
			if (flags & XBPS_VERBOSE)
				printf("WARNING: can't remove file %s (%s)\n",
				    file, strerror(errno));
			goto out;
		}
		if (flags & XBPS_VERBOSE)
			printf("Removed file: %s\n", file);

		goto out;
	} else if (strcmp(type, "dir") == 0) {
		if ((bobj = prop_dictionary_get(obj, "keep")) != NULL) {
			/* Skip permanent directory. */
			return 0;
		}

		if ((rv = rmdir(path)) == -1) {
			if (errno == ENOTEMPTY)
				goto out;

			if (flags & XBPS_VERBOSE) {
				printf("WARNING: can't remove "
				    "directory %s (%s)\n", file,
				    strerror(errno));
				goto out;
			}
			if (flags & XBPS_VERBOSE)
				printf("Removed directory: %s\n", file);
		}
	} else if (strcmp(type, "link") == 0) {
		if ((rv = remove(path)) == -1) {
			if (flags & XBPS_VERBOSE)
				printf("WARNING: can't remove link %s (%s)\n",
				    file, strerror(errno));
			goto out;
		}
		if (flags & XBPS_VERBOSE)
			printf("Removed link: %s\n", file);
	}

out:
	free(path);

	return 0;
}

int
xbps_remove_binary_pkg(const char *pkgname, bool update)
{
	prop_dictionary_t dict;
	const char *rootdir = xbps_get_rootdir();
	char *path, *buf;
	int fd, rv = 0;
	bool prepostf = false;

	assert(pkgname != NULL);

	if (strcmp(rootdir, "") == 0)
		rootdir = "/";

	if (rootdir) {
		if (chdir(rootdir) == -1)
			return errno;
	} else {
		if (chdir("/") == -1)
			return errno;
		rootdir = "";
        }

	/* Check if pkg is installed */
	if (xbps_check_is_installed_pkgname(pkgname) == false)
		return ENOENT;

	buf = xbps_xasprintf("%s/%s/metadata/%s/REMOVE", rootdir,
	    XBPS_META_PATH, pkgname);
	if (buf == NULL)
		return errno;

	/*
	 * Find out if the REMOVE file exists.
	 */
	if ((fd = open(buf, O_RDONLY)) == -1) {
		if (errno != ENOENT) {
			free(buf);
			return errno;
		}
	} else {
		/*
		 * Run the pre remove action.
		 */
		(void)close(fd);
		prepostf = true;
		(void)printf("\n");
		(void)fflush(stdout);
		rv = xbps_file_exec(buf, rootdir, "pre", pkgname, NULL);
		if (rv != 0) {
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
	path = xbps_xasprintf("%s/%s/metadata/%s/files.plist",
	    rootdir, XBPS_META_PATH, pkgname);
	if (path == NULL) {
		free(buf);
		return errno;
	}

	dict = prop_dictionary_internalize_from_file(path);
	if (dict == NULL) {
		free(buf);
		free(path);
		return errno;
	}
	free(path);

	rv = xbps_callback_array_iter_in_dict(dict, "filelist",
	    remove_pkg_files, NULL);
	if (rv != 0) {
		free(buf);
		prop_object_release(dict);
		return rv;
	}
	prop_object_release(dict);

	/*
	 * Run the post remove action if REMOVE file is there.
	 */
	if (prepostf) {
		if ((rv = xbps_file_exec(buf, rootdir, "post",
		     pkgname, NULL)) != 0) {
			printf("%s: postrm action target error (%s)\n",
			    pkgname, strerror(errno));
			free(buf);
			return rv;
		}
	}
	free(buf);

	/*
	 * Update the required_by array of all required dependencies
	 * and unregister package if this is really a removal and
	 * not an update.
	 */
	if (update == false) {
		rv = xbps_requiredby_pkg_remove(pkgname);
		if (rv != 0)
			return rv;
		/*
		 * Unregister pkg from database.
		 */
		rv = xbps_unregister_pkg(pkgname);
		if (rv != 0)
			return rv;
	}

	/*
	 * Remove pkg metadata directory.
	 */
	return xbps_remove_binary_pkg_meta(pkgname);
}
