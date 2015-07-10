#include <stdarg.h>
#include <stdio.h>
#define _GNU_SOURCE
#include <errno.h>

void error(int status, int errnum, const char* format, ...)
{
	va_list ap;

	fflush(stdout);
	fprintf(stderr, "%s: ", program_invocation_name);
	va_start(ap, format);
	vfprintf(stderr, format, ap);
	va_end(ap);
	if (errnum)
		fprintf(stderr, ":%d", errnum);
	if (status)
		exit(status);
}
