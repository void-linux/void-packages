/* 32 bit int types */
#ifndef STDINT_LOCAL_H
#define STDINT_LOCAL_H
typedef signed char             int8_t;
typedef short int               int16_t;
typedef int                     int32_t;
# if defined(__x86_64__)
typedef long int                int64_t;
#else
typedef long long int           int64_t;
#endif

/* Unsigned.  */
typedef unsigned char           uint8_t;
typedef unsigned short int      uint16_t;
typedef unsigned int            uint32_t;
# if defined(__x86_64__)
typedef unsigned long int       uint64_t;
#else
typedef unsigned long long int  uint64_t;
#endif

#endif
