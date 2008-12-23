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
	if (argc<3) {
		printf("Usage: xbps-cmpver [old] [new]\n");
		printf(" xbpks-cmpver foo-1.2 foo-2.2   # $? = 1\n");
		printf(" xbpks-cmpver foo-1.2 foo-1.2   # $? = 0\n");
		return 1;
	}

#if UNIT_TEST
	printf("1.2 2.2 = %d\n", chkver("1.2", "2.2"));
	printf("1.0 10.3 = %d\n", chkver("1.0", "10.3"));
	printf("1.0 1.0  = %d\n", chkver("1.0", "1.0"));
	printf("1.0 1.2  = %d\n", chkver("1.0", "1.2"));
	printf("1.0.1 1.0.2 = %d\n", chkver("1.0.1", "1.0.2"));
	printf("1.0beta 1.0rc1 = %d\n", chkver("1.0beta", "1.0rc1"));
#endif

	return (xbps_cmpver_packages(argv[1], argv[2]) > 0)?1:0;
}
