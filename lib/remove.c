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

#include <xbps_api.h>

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

int
xbps_remove_binary_pkg(const char *pkgname, const char *destdir)
{
	FILE *flist;
	char path[PATH_MAX - 1], line[LINE_MAX - 1], *p, *buf;
	int fd, rv = 0;
	size_t len = 0;
	bool prepostf = false;

	assert(pkgname != NULL);

	if (destdir == NULL)
		destdir = "";

	/*
	 * This length is '%s%s/metadata/%s/prepost-action' not
	 * including nul.
	 */
	len = strlen(XBPS_META_PATH) + strlen(destdir) + strlen(pkgname) + 26;
	buf = malloc(len + 1);
	if (buf == NULL)
		return errno;

	if (snprintf(buf, len + 1, "%s%s/metadata/%s/prepost-action",
	    destdir, XBPS_META_PATH, pkgname) < 0) {
		free(buf);
		return -1;
	}

	/* Find out if the prepost-action file exists */
	if ((fd = open(buf, O_RDONLY)) == -1) {
		if (errno != ENOENT) {
			rv = errno;
			goto out;
		}
	} else {
		/* Run the preremove action */
		(void)close(fd);
		prepostf = true;
		if ((rv = xbps_file_exec(buf, destdir, "prerm", pkgname,
		     NULL)) != 0) {
			printf("%s: prerm action target error (%s)\n", pkgname,
			    strerror(errno));
			goto out;
		}
	}

	(void)snprintf(path, sizeof(path), "%s%s/metadata/%s/flist",
	    destdir, XBPS_META_PATH, pkgname);

	if ((flist = fopen(path, "r")) == NULL) {
		rv = errno;
		goto out;
	}

	while (!feof(flist)) {
		p = fgets(line, sizeof(line), flist);
		if (p == NULL) {
			if (feof(flist))
				break;
			if (ferror(flist)) {
				rv = errno;
				break;
			}
		}
		if (strlen(line) == 0 || line[0] == '#' ||
		    isspace((unsigned char)line[0]) != 0)
			continue;

		len = strlen(line) + 1;
		p = calloc(1, len);
		if (p == NULL) {
			rv = errno;
			break;
		}

		(void)strncpy(p, line, len - 2);
		(void)snprintf(path, sizeof(path), "%s%s",
		    destdir, p);

		/*
		 * Remove the file or the directory if it's empty.
		 */
		if ((rv = unlink(path)) == -1) {
			if (errno == EISDIR) {
				if ((rv = rmdir(path)) == -1) {
					if (errno == ENOTEMPTY)  {
						rv = 0;
						goto next;
					}
					printf("WARNING: can't remove directory"
					    " %s (%s)\n", path, strerror(errno));
					goto next;
				}
				printf("Removed directory: %s\n", path);
				goto next;
			}
			printf("WARNING: can't remove file %s (%s)\n", path,
			    strerror(errno));
			goto next;
		}

		printf("Removed file: %s\n", path);
next:
		free(p);
		p = NULL;
	}
	(void)fclose(flist);

	/* If successful, unregister pkg from db */
	if (rv == 0) {
		if (((rv = xbps_unregister_pkg(pkgname)) == 0) && prepostf) {
			/* Run the postremove action target */
			if ((rv = xbps_file_exec(buf, destdir, "postrm",
			     pkgname, NULL)) != 0) {
				printf("%s: postrm action target error (%s)\n",
				    pkgname, strerror(errno));
			}
		}
	}

out:
	free(buf);

	return rv;
}
