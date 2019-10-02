#include "u.h"
#include "libc.h"

int
tas(int *x)
{
	/* Use the GCC builtin __sync_add_and_fetch() for optimal code */
	int v = __sync_add_and_fetch(x, 1);
	switch(v) {
	case 0:
	case 1:
		return v;
	default:
		print("canlock: corrupted 0x%lux\n", v);
		return 1;
	}
}

