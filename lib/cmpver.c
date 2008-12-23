/* 
 * Compare package and version strings
 * @ 2008
 * Author: pancake <youterm.com>
 */
#include <stdio.h>
#include <string.h>
#include <xbps_api.h>

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

int
xbps_cmpver_versions(const char *a0, const char *a1)
{
	int p0,p1;
	int v0 = ver2int(a0, &p0, 0);
	int v1 = ver2int(a1, &p1, p0);
	return v1-v0;
}

int
xbps_cmpver_packages(const char *a0, const char *b0)
{
	char *a = strrchr(a0, '-');
	char *b = strrchr(b0, '-');

	assert(a != NULL || b != NULL);

	return xbps_cmpver_versions(a+1, b+1);
}
