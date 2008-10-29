/* 
 * Compare package and version strings
 * @ 2008
 * Author: pancake <youterm.com>
 */
#include <stdio.h>
#include <string.h>

static int chkchr(const char *ch)
{
	if (*ch>='0' && *ch<='9')
		return *ch-'0';
	if (ch[1]=='\0') {
		if (*ch>='a'&&*ch<='z'){
			return *ch-'a';
		}
	}
	switch(*ch) {
	case 'a': if (ch[1]=='l')
			return 0xa;
		return -1;
	case 'b': return 0xb;
	case 'r': return 0xc;
	}
	return -1;
}

static int ver2int(const char *a0, int *pow, int mpow)
{
	int r,ret = 0;
	int pos = 0;
	const char *a = a0+strlen(a0)-1;
	for(*pow=0;a>=a0;a=a-1) {
		if (*a=='.') {
			 *pow=*pow+1;
		} else {
			r = chkchr(a);
			if (r != -1)
				ret+=((r+1)*((*pow)+1))<<pos++;
		}
		if (mpow>0 && *pow > mpow)
			break;
	}
	return ret;
}

int chkver(const char *a0, const char *a1)
{
	int p0,p1;
	int v0 = ver2int(a0, &p0, 0);
	int v1 = ver2int(a1, &p1, p0);
	return v1-v0;
}

int chkpkg(const char *a0, const char *b0)
{
	char *a = strrchr(a0, '-');
	char *b = strrchr(b0, '-');

	if (a == NULL || b== NULL) {
		fprintf(stderr, "Invalid package names\n");
		return 0;
	}
	return chkver(a+1, b+1);
}

#if UNIT_TEST
	printf("1.2 2.2 = %d\n", chkver("1.2", "2.2"));
	printf("1.0 10.3 = %d\n", chkver("1.0", "10.3"));
	printf("1.0 1.0  = %d\n", chkver("1.0", "1.0"));
	printf("1.0 1.2  = %d\n", chkver("1.0", "1.2"));
	printf("1.0.1 1.0.2 = %d\n", chkver("1.0.1", "1.0.2"));
	printf("1.0beta 1.0rc1 = %d\n", chkver("1.0beta", "1.0rc1"));
#endif

int main(int argc, char **argv)
{
	if (argc<3) {
		printf("Usage: ./xbps-cmpver [old] [new]\n");
		printf(" ./xbpks-cmpver foo-1.2 foo-2.2   # $? = 1\n");
		printf(" ./xbpks-cmpver foo-1.2 foo-1.2   # $? = 0\n");
		return 1;
	}
	return (chkpkg(argv[1], argv[2]) > 0)?1:0;
}
