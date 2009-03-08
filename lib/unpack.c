/*-
 * Copyright (c) 2008-2009 Juan Romero Pardines.
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
#include <sys/stat.h>

#include <xbps_api.h>

static int unpack_archive_init(prop_dictionary_t, const char *,
			       const char *, int);
static int unpack_archive_fini(struct archive *, const char *, int,
			       prop_dictionary_t);

int
xbps_unpack_binary_pkg(prop_dictionary_t repo, prop_dictionary_t pkg,
		       const char *destdir, int flags)
{
	prop_string_t filename, repoloc, arch;
	char *binfile, *path;
	int rv = 0;

	assert(pkg != NULL);

	/* Append filename to the full path for binary pkg */
	filename = prop_dictionary_get(pkg, "filename");
	arch = prop_dictionary_get(pkg, "architecture");
	if (repo)
		repoloc = prop_dictionary_get(repo, "location-local");
	else
		repoloc = prop_dictionary_get(pkg, "repository");

	path = xbps_append_full_path(false,
	    prop_string_cstring_nocopy(repoloc),
	    prop_string_cstring_nocopy(arch));
	if (path == NULL)
		return EINVAL;

	binfile = xbps_append_full_path(false, path,
	    prop_string_cstring_nocopy(filename));
	if (binfile == NULL) {
		free(path);
		return EINVAL;
	}
	free(path);

	rv = unpack_archive_init(pkg, destdir, binfile, flags);
	free(binfile);
	return rv;
}


static int
unpack_archive_init(prop_dictionary_t pkg, const char *destdir,
		    const char *binfile, int flags)
{
	struct archive *ar;
	int pkg_fd, rv;

	assert(pkg != NULL);
	assert(binfile != NULL);

	if ((pkg_fd = open(binfile, O_RDONLY)) == -1)
		return errno;

	ar = archive_read_new();
	if (ar == NULL) {
		(void)close(pkg_fd);
		return ENOMEM;
	}

	/* Enable support for all format and compression methods */
	archive_read_support_compression_all(ar);
	archive_read_support_format_all(ar);

	/* 2048 is arbitrary... dunno what value is better. */
	if ((rv = archive_read_open_fd(ar, pkg_fd, 2048)) != 0) {
		archive_read_finish(ar);
		(void)close(pkg_fd);
		return rv;
	}

	rv = unpack_archive_fini(ar, destdir, flags, pkg);
	/*
	 * If installation of package was successful, make sure the package
	 * is really on storage (if possible).
	 */
	if (rv == 0)
		if (fdatasync(pkg_fd) == -1)
			rv = errno;

	archive_read_finish(ar);
	(void)close(pkg_fd);

	return rv;
}
/*
 * Flags for extracting files in binary packages.
 */
#define EXTRACT_FLAGS	ARCHIVE_EXTRACT_SECURE_NODOTDOT | \
			ARCHIVE_EXTRACT_SECURE_SYMLINKS | \
			ARCHIVE_EXTRACT_NO_OVERWRITE | \
			ARCHIVE_EXTRACT_NO_OVERWRITE_NEWER
#define FEXTRACT_FLAGS	ARCHIVE_EXTRACT_OWNER | ARCHIVE_EXTRACT_PERM | \
			ARCHIVE_EXTRACT_TIME | EXTRACT_FLAGS

/*
 * TODO: remove printfs and return appropiate errors to be interpreted by
 * the consumer.
 */
static int
unpack_archive_fini(struct archive *ar, const char *destdir, int flags,
		    prop_dictionary_t pkg)
{
	struct archive_entry *entry;
	size_t len;
	const char *prepost = "./INSTALL";
	const char *pkgname, *version;
	char *buf;
	int rv = 0, lflags = 0;
	bool actgt = false;

	assert(ar != NULL);
	assert(pkg != NULL);

	prop_dictionary_get_cstring_nocopy(pkg, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(pkg, "version", &version);

	if (getuid() == 0)
		lflags = FEXTRACT_FLAGS;
	else
		lflags = EXTRACT_FLAGS;

	/*
	 * This length is '.%s/metadata/%s/INSTALL' + NULL.
	 */
	len = strlen(XBPS_META_PATH) + strlen(pkgname) + 20;
	buf = malloc(len);
	if (buf == NULL)
		return ENOMEM;

	if (snprintf(buf, len, ".%s/metadata/%s/INSTALL",
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
			printf("\n");
			(void)fflush(stdout);

			archive_entry_set_pathname(entry, buf);

			if (archive_read_extract(ar, entry, lflags) != 0) {
				if ((rv = archive_errno(ar)) != EEXIST)
					break;
			}

			if ((rv = xbps_file_exec(buf, destdir, "pre",
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
		if (archive_read_extract(ar, entry, lflags) != 0) {
			rv = archive_errno(ar);
			if (rv != EEXIST) {
				printf("ERROR: couldn't unpack %s (%s), "
				    "exiting!\n", archive_entry_pathname(entry),
				    archive_error_string(ar));
				(void)fflush(stdout);
				break;
			} else if (rv == EEXIST) {
				if (flags & XBPS_UNPACK_VERBOSE) {
					printf("WARNING: ignoring existent "
					    "path: %s\n",
					    archive_entry_pathname(entry));
					(void)fflush(stdout);
				}
				rv = 0;
				continue;
			}
		}
		if (flags & XBPS_UNPACK_VERBOSE) {
			printf(" %s\n", archive_entry_pathname(entry));
			(void)fflush(stdout);
		}
	}

	if (rv == 0 && actgt) {
		/*
		 * Run the post installaction action target, if package
		 * contains the script.
		 */
		if ((rv = xbps_file_exec(buf, destdir, "post",
		     pkgname, version, NULL)) != 0) {
			printf("%s: postinst action target error %s\n",
			    pkgname, strerror(errno));
			(void)fflush(stdout);
		}
	}

	free(buf);

	return rv;
}
