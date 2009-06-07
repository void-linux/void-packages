/*
 * Compare package and version strings
 * @ 2008
 * Author: pancake <youterm.com>
 */
#include <stdio.h>
#include <string.h>
#include <xbps_api.h>

int main(int argc, char **argv)
{
	if (argc < 3) {
		printf("Usage: xbps-cmpver [installed] [required]\n");
		printf(" xbps-cmpver foo-1.2 foo-2.2   # $? = 1\n");
		printf(" xbps-cmpver foo-1.2 foo-1.1.0 # $? = 0\n");
		printf(" xbps-cmpver foo-1.2 foo-1.2   # $? = 0\n");
		return 1;
	}

	return xbps_cmpver(argv[1], argv[2]);
}
