#ifndef _ERROR_H_
#define _ERROR_H_

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

static unsigned int error_message_count = 0;

static inline void error(int status, int errnum, const char* format, ...)
{
	va_list ap;
	fprintf(stderr, "%s: ", program_invocation_name);
	va_start(ap, format);
	vfprintf(stderr, format, ap);
	va_end(ap);
	if (errnum)
		fprintf(stderr, ": %s", strerror(errnum));
	fprintf(stderr, "\n");
	error_message_count++;
	if (status)
		exit(status);
}

#endif	/* _ERROR_H_ */
