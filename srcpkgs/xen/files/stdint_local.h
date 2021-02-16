/* Copied from Alpine Linux's aports repo: */
/* 32 bit int types */
#ifndef STDINT_LOCAL_H
#define STDINT_LOCAL_H
typedef	__INT8_TYPE__		int8_t;
typedef __INT16_TYPE__		int16_t;
typedef __INT32_TYPE__		int32_t;
typedef __INT64_TYPE__		int64_t;
typedef __INTPTR_TYPE__		intptr_t;

/* Unsigned.  */
typedef	__UINT8_TYPE__		uint8_t;
typedef __UINT16_TYPE__		uint16_t;
typedef __UINT32_TYPE__		uint32_t;
typedef __UINT64_TYPE__		uint64_t;
typedef __UINTPTR_TYPE__	uintptr_t;

#define INTPTR_MAX	0x7fffffffffffffffL
#define UINTPTR_MAX	0xffffffffffffffffUL
#endif
