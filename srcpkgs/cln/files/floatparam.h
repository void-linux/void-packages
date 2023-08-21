/* Rounding modes, for use below */
#define rounds_to_nearest        0  /* 0.5 ulp */
#define rounds_to_zero           1  /* 1 ulp */
#define rounds_to_infinity       2  /* 1 ulp */
#define rounds_to_minus_infinity 3  /* 1 ulp */

/* Properties of type \`float: */
/* Largest n for which 1+2^(-n) is exactly represented is 23. */
/* Largest n for which 1-2^(-n) is exactly represented is 24. */
#define float_mant_bits 24
#define float_rounds rounds_to_nearest

/* Properties of type \`double': */
/* Largest n for which 1+2^(-n) is exactly represented is 52. */
/* Largest n for which 1-2^(-n) is exactly represented is 53. */
#define double_mant_bits 53
#define double_rounds rounds_to_nearest
