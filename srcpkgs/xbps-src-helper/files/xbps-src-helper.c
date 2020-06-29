/*-
 * Copyright (c) 2020 Érico Nogueira Rolim
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

#include <errno.h>
#include <ftw.h>
#include <getopt.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

enum supported_actions {
NOT_FOUND,
ELF_IN_USRSHARE,
};

bool elf_in_usrshare = false;

int
inspect_elf(
	const char *filepath,
	const struct stat *info,
	const int typeflag,
	struct FTW *pathinfo)
{
	(void) pathinfo;
	(void) info;

	FILE *file;
	size_t read_bytes;
	uint8_t bytes[4] = {}, elf_header[4] = { 0x7F, 'E', 'L', 'F' };
	file = NULL;
	read_bytes = 0;

	if (typeflag != FTW_F) {
		return 0;
	}

	file = fopen(filepath, "r");
	if (file == NULL) {
		fprintf(stderr, "File %s couldn't be read.\nError: %m\n", filepath);
		exit(1);
	}

	read_bytes = fread(bytes, 1, 4, file);
	if (read_bytes < 4) {
		// file is too small to be an executable
		return 0;
	}

	if (memcmp(bytes, elf_header, 4) == 0) {
		// file is an elf file
		printf("/%s\n", filepath);
		elf_in_usrshare = true;
	}

	fclose(file);

	return 0;
}

int
main(int argc, char **argv)
{
	const struct option longopts[] = {
		{ "elf-in-usrshare", required_argument, NULL, ELF_IN_USRSHARE },
		{ NULL, 0, NULL, 0 }
	};

	int c, rv;
	enum supported_actions run;
	char *path;

	c = rv = 0;
	run = NOT_FOUND;
	path = NULL;

	while ((c = getopt_long_only(argc, argv, "", longopts, NULL)) != -1) {
		switch (c) {
		case ELF_IN_USRSHARE:
			path = optarg;
			run = c;
			break;
		}
	}

	if (run == NOT_FOUND) {
		fputs("No action specified!", stderr);
		exit(1);
	} else {
		rv = chdir(path);
		if (rv == -1) {
			if (errno == ENOENT) {
				fputs("Directory doesn't exist, skipping...", stderr);
			} else {
				fprintf(stderr, "Can't move into directory %s!\nError: %m\n", path);
				exit(1);
			}
		}

		if (run == ELF_IN_USRSHARE) {
			rv = nftw("usr/share", inspect_elf, 100, 0);
			if (rv != 0) {
				errno = rv;
				fprintf(stderr, "Error while traversing tree: %m\n");
				exit(1);
			}

			if (elf_in_usrshare) {
				fputs("ELF files were found in usr/share", stderr);
			}
		}
	}

	return 0;
}
