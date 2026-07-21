#ifndef _ERROR_H_
#define _ERROR_H_

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#warning usage of non-standard #include <error.h> is deprecated

static unsigned int error_message_count = 0;

static inline void error(int status, int errnum, const char* format, ...)
{
	/* should be fflush(stdout), but that's unspecified if stdout has been closed;
	 * stick with fflush(NULL) for simplicity (glibc checks if the fd is still valid) */
	fflush(NULL);

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

static int error_one_per_line = 0;

static inline void error_at_line(int status, int errnum, const char *filename,
		unsigned int linenum, const char *format, ...)
{
	va_list ap;
	if (error_one_per_line) {
		static const char *old_filename;
		static int old_linenum;
		if (linenum == old_linenum && filename == old_filename)
			return;
		old_filename = filename;
		old_linenum = linenum;
	}
	fprintf(stderr, "%s: %s:%u: ", program_invocation_name, filename, linenum);
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
