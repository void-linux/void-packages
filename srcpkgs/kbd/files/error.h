#ifndef ERROR_H
#define ERROR_H

#include <stdio.h>
#include <stdarg.h>
#include <err.h>

static inline void error(int status, int errnum, const char *fmt, ...)
{
	va_list ap;
	void (*errfunc[2])(int, const char *, va_list) = { &verr, &verrx };
	void (*warnfunc[2])(const char *, va_list) = { &vwarn, &vwarnx };
	fflush(stdout);
	va_start(ap, fmt);
	if (status != 0)
		errfunc[errnum==0](status, fmt, ap); /* does not return */
	warnfunc[errnum==0](fmt, ap);
	va_end(ap);
}
#endif
