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

	return rv;
}

int
xbps_remove_binary_pkg(const char *pkgname, const char *destdir)
{
	FILE *flist;
	char path[PATH_MAX - 1], line[LINE_MAX - 1], *p;
	int rv = 0;
	size_t len = 0;

	assert(pkgname != NULL);

	if (destdir) {
		if ((rv = chdir(destdir)) != 0)
			return errno;
	} else
		destdir = "";

	(void)snprintf(path, sizeof(path), "%s%s/metadata/%s/flist",
	    destdir, XBPS_META_PATH, pkgname);

	if ((flist = fopen(path, "r")) == NULL)
		return errno;

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
	return rv ? rv : xbps_unregister_pkg(pkgname);
}
