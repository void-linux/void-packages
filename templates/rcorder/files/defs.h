#ifndef _DEFS_H_
#define _DEFS_H_

#include <stdio.h>
#include <stdlib.h>

#define FPARSELN_UNESCESC	0x01
#define FPARSELN_UNESCCONT	0x02
#define FPARSELN_UNESCCOMM	0x04
#define FPARSELN_UNESCREST	0x08
#define FPARSELN_UNESCALL	0x0f

char	*fgetln(FILE *, size_t *);
char	*fparseln(FILE *, size_t *, size_t *, const char [3], int);
void	*emalloc(size_t);
char	*estrdup(const char *);
void	*erealloc(void *, size_t);
void	*ecalloc(size_t, size_t);

#endif /* ! _DEFS_H_ */
