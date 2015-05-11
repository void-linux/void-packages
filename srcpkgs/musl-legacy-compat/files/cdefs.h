#warning usage of non-standard #include <sys/cdefs.h> is deprecated

#undef __P
#undef __PMT

#define __P(args)	args
#define __PMT(args)	args

#define __CONCAT(x,y)	x ## y
#define __STRING(x)	#x

#ifdef  __cplusplus
# define __BEGIN_DECLS	extern "C" {
# define __END_DECLS	}
#else
# define __BEGIN_DECLS
# define __END_DECLS
#endif

#if defined(__GNUC__) && !defined(__cplusplus)
# define __THROW	__attribute__ ((__nothrow__))
# define __NTH(fct)	__attribute__ ((__nothrow__)) fct
#else
# define __THROW
# define __NTH(fct)     fct
#endif
