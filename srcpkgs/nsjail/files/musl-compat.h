#if !defined(MUSL_COMPAT_H)
#define MUSL_COMPAT_H

# define TEMP_FAILURE_RETRY(expression) \
	(__extension__			\
	 ({ long int __result;		\
	  do __result = (long int) (expression); \
	  while (__result == -1L && errno == EINTR); \
	  __result; }))

#endif /* !defined(MUSL_COMPAT_H) */
