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

#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <inttypes.h>
#include <libgen.h>

#include <xbps_api.h>

static void
usage(void)
{
	fprintf(stderr, "usage: xbps-digest <file> <file1+N> ...\n");
	exit(EXIT_FAILURE);
}

int
main(int argc, char **argv)
{
	SHA256_CTX ctx;
	uint8_t buffer[BUFSIZ * 20], *digest;
	ssize_t bytes;
	int i, fd;

	if (argc < 2)
		usage();

	for (i = 1; i < argc; i++) {
		if ((fd = open(argv[i], O_RDONLY)) == -1) {
			printf("xbps-digest: cannot open %s (%s)\n", argv[i],
			    strerror(errno));
			exit(EXIT_FAILURE);
		}

		digest = malloc(SHA256_DIGEST_STRING_LENGTH);
		if (digest == NULL) {
			printf("xbps-digest: malloc failed (%s)\n",
			    strerror(errno));
			exit(EXIT_FAILURE);
		}

		SHA256_Init(&ctx);
		while ((bytes = read(fd, buffer, sizeof(buffer))) > 0)
			SHA256_Update(&ctx, buffer, (size_t)bytes);

		printf("%s\n", SHA256_End(&ctx, digest));
		free(digest);
		close(fd);
	}

	exit(EXIT_SUCCESS);
}
