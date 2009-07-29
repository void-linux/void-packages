/* $NetBSD: sha2.c,v 1.18 2009/06/25 14:05:18 joerg Exp $ */
/*	$KAME: sha2.c,v 1.9 2003/07/20 00:28:38 itojun Exp $	*/

/*
 * sha2.c
 *
 * Version 1.0.0beta1
 *
 * Written by Aaron D. Gifford <me@aarongifford.com>
 *
 * Copyright 2000 Aaron D. Gifford.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) AND CONTRIBUTOR(S) ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR(S) OR CONTRIBUTOR(S) BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <inttypes.h>
#include <libgen.h>

#include "xbps_api.h"

/*** SHA-256 Various Length Definitions ***********************/
/* NOTE: Most of these are in sha2.h */
#define SHA256_SHORT_BLOCK_LENGTH	(SHA256_BLOCK_LENGTH - 8)

/*** THE SIX LOGICAL FUNCTIONS ****************************************/
/*
 * Bit shifting and rotation (used by the six SHA-XYZ logical functions:
 *
 *   NOTE:  The naming of R and S appears backwards here (R is a SHIFT and
 *   S is a ROTATION) because the SHA-256/384/512 description document
 *   (see http://csrc.nist.gov/cryptval/shs/sha256-384-512.pdf) uses this
 *   same "backwards" definition.
 */
/* Shift-right (used in SHA-256, SHA-384, and SHA-512): */
#define R(b,x) 		((x) >> (b))
/* 32-bit Rotate-right (used in SHA-256): */
#define S32(b,x)	(((x) >> (b)) | ((x) << (32 - (b))))

/* Two of six logical functions used in SHA-256, SHA-384, and SHA-512: */
#define Ch(x,y,z)	(((x) & (y)) ^ ((~(x)) & (z)))
#define Maj(x,y,z)	(((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))

/* Four of six logical functions used in SHA-256: */
#define Sigma0_256(x)	(S32(2,  (x)) ^ S32(13, (x)) ^ S32(22, (x)))
#define Sigma1_256(x)	(S32(6,  (x)) ^ S32(11, (x)) ^ S32(25, (x)))
#define sigma0_256(x)	(S32(7,  (x)) ^ S32(18, (x)) ^ R(3 ,   (x)))
#define sigma1_256(x)	(S32(17, (x)) ^ S32(19, (x)) ^ R(10,   (x)))

/*** INTERNAL FUNCTION PROTOTYPES *************************************/
/* NOTE: These should not be accessed directly from outside this
 * library -- they are intended for private internal visibility/use
 * only.
 */
static void SHA256_Transform(SHA256_CTX *, const uint32_t*);
static int SHA256_Final(uint8_t *, SHA256_CTX *);


/*** SHA-XYZ INITIAL HASH VALUES AND CONSTANTS ************************/
/* Hash constant words K for SHA-256: */
static const uint32_t K256[64] = {
	0x428a2f98UL, 0x71374491UL, 0xb5c0fbcfUL, 0xe9b5dba5UL,
	0x3956c25bUL, 0x59f111f1UL, 0x923f82a4UL, 0xab1c5ed5UL,
	0xd807aa98UL, 0x12835b01UL, 0x243185beUL, 0x550c7dc3UL,
	0x72be5d74UL, 0x80deb1feUL, 0x9bdc06a7UL, 0xc19bf174UL,
	0xe49b69c1UL, 0xefbe4786UL, 0x0fc19dc6UL, 0x240ca1ccUL,
	0x2de92c6fUL, 0x4a7484aaUL, 0x5cb0a9dcUL, 0x76f988daUL,
	0x983e5152UL, 0xa831c66dUL, 0xb00327c8UL, 0xbf597fc7UL,
	0xc6e00bf3UL, 0xd5a79147UL, 0x06ca6351UL, 0x14292967UL,
	0x27b70a85UL, 0x2e1b2138UL, 0x4d2c6dfcUL, 0x53380d13UL,
	0x650a7354UL, 0x766a0abbUL, 0x81c2c92eUL, 0x92722c85UL,
	0xa2bfe8a1UL, 0xa81a664bUL, 0xc24b8b70UL, 0xc76c51a3UL,
	0xd192e819UL, 0xd6990624UL, 0xf40e3585UL, 0x106aa070UL,
	0x19a4c116UL, 0x1e376c08UL, 0x2748774cUL, 0x34b0bcb5UL,
	0x391c0cb3UL, 0x4ed8aa4aUL, 0x5b9cca4fUL, 0x682e6ff3UL,
	0x748f82eeUL, 0x78a5636fUL, 0x84c87814UL, 0x8cc70208UL,
	0x90befffaUL, 0xa4506cebUL, 0xbef9a3f7UL, 0xc67178f2UL
};

/* Initial hash value H for SHA-256: */
static const uint32_t sha256_initial_hash_value[8] = {
	0x6a09e667UL,
	0xbb67ae85UL,
	0x3c6ef372UL,
	0xa54ff53aUL,
	0x510e527fUL,
	0x9b05688cUL,
	0x1f83d9abUL,
	0x5be0cd19UL
};

/*** SHA-256: *********************************************************/
int
SHA256_Init(SHA256_CTX *context)
{
	if (context == NULL)
		return 1;

	memcpy(context->state, sha256_initial_hash_value,
	    (size_t)(SHA256_DIGEST_LENGTH));
	memset(context->buffer, 0, (size_t)(SHA256_BLOCK_LENGTH));
	context->bitcount = 0;

	return 1;
}

#ifdef SHA2_UNROLL_TRANSFORM

/* Unrolled SHA-256 round macros: */

#define ROUND256_0_TO_15(a,b,c,d,e,f,g,h)	\
	W256[j] = be32toh(*data);		\
	++data;					\
	T1 = (h) + Sigma1_256(e) + Ch((e), (f), (g)) + \
             K256[j] + W256[j]; \
	(d) += T1; \
	(h) = T1 + Sigma0_256(a) + Maj((a), (b), (c)); \
	j++

#define ROUND256(a,b,c,d,e,f,g,h)	\
	s0 = W256[(j+1)&0x0f]; \
	s0 = sigma0_256(s0); \
	s1 = W256[(j+14)&0x0f]; \
	s1 = sigma1_256(s1); \
	T1 = (h) + Sigma1_256(e) + Ch((e), (f), (g)) + K256[j] + \
	     (W256[j&0x0f] += s1 + W256[(j+9)&0x0f] + s0); \
	(d) += T1; \
	(h) = T1 + Sigma0_256(a) + Maj((a), (b), (c)); \
	j++

static void
SHA256_Transform(SHA256_CTX *context, const uint32_t *data)
{
	uint32_t	a, b, c, d, e, f, g, h, s0, s1;
	uint32_t	T1, *W256;
	int		j;

	W256 = (uint32_t *)context->buffer;

	/* Initialize registers with the prev. intermediate value */
	a = context->state[0];
	b = context->state[1];
	c = context->state[2];
	d = context->state[3];
	e = context->state[4];
	f = context->state[5];
	g = context->state[6];
	h = context->state[7];

	j = 0;
	do {
		/* Rounds 0 to 15 (unrolled): */
		ROUND256_0_TO_15(a,b,c,d,e,f,g,h);
		ROUND256_0_TO_15(h,a,b,c,d,e,f,g);
		ROUND256_0_TO_15(g,h,a,b,c,d,e,f);
		ROUND256_0_TO_15(f,g,h,a,b,c,d,e);
		ROUND256_0_TO_15(e,f,g,h,a,b,c,d);
		ROUND256_0_TO_15(d,e,f,g,h,a,b,c);
		ROUND256_0_TO_15(c,d,e,f,g,h,a,b);
		ROUND256_0_TO_15(b,c,d,e,f,g,h,a);
	} while (j < 16);

	/* Now for the remaining rounds to 64: */
	do {
		ROUND256(a,b,c,d,e,f,g,h);
		ROUND256(h,a,b,c,d,e,f,g);
		ROUND256(g,h,a,b,c,d,e,f);
		ROUND256(f,g,h,a,b,c,d,e);
		ROUND256(e,f,g,h,a,b,c,d);
		ROUND256(d,e,f,g,h,a,b,c);
		ROUND256(c,d,e,f,g,h,a,b);
		ROUND256(b,c,d,e,f,g,h,a);
	} while (j < 64);

	/* Compute the current intermediate hash value */
	context->state[0] += a;
	context->state[1] += b;
	context->state[2] += c;
	context->state[3] += d;
	context->state[4] += e;
	context->state[5] += f;
	context->state[6] += g;
	context->state[7] += h;

	/* Clean up */
	a = b = c = d = e = f = g = h = T1 = 0;
}

#else /* SHA2_UNROLL_TRANSFORM */

void
SHA256_Transform(SHA256_CTX *context, const uint32_t *data)
{
	uint32_t	a, b, c, d, e, f, g, h, s0, s1;
	uint32_t	T1, T2, *W256;
	int		j;

	W256 = (uint32_t *)(void *)context->buffer;

	/* Initialize registers with the prev. intermediate value */
	a = context->state[0];
	b = context->state[1];
	c = context->state[2];
	d = context->state[3];
	e = context->state[4];
	f = context->state[5];
	g = context->state[6];
	h = context->state[7];

	j = 0;
	do {
		W256[j] = be32toh(*data);
		++data;
		/* Apply the SHA-256 compression function to update a..h */
		T1 = h + Sigma1_256(e) + Ch(e, f, g) + K256[j] + W256[j];
		T2 = Sigma0_256(a) + Maj(a, b, c);
		h = g;
		g = f;
		f = e;
		e = d + T1;
		d = c;
		c = b;
		b = a;
		a = T1 + T2;

		j++;
	} while (j < 16);

	do {
		/* Part of the message block expansion: */
		s0 = W256[(j+1)&0x0f];
		s0 = sigma0_256(s0);
		s1 = W256[(j+14)&0x0f];
		s1 = sigma1_256(s1);

		/* Apply the SHA-256 compression function to update a..h */
		T1 = h + Sigma1_256(e) + Ch(e, f, g) + K256[j] +
		     (W256[j&0x0f] += s1 + W256[(j+9)&0x0f] + s0);
		T2 = Sigma0_256(a) + Maj(a, b, c);
		h = g;
		g = f;
		f = e;
		e = d + T1;
		d = c;
		c = b;
		b = a;
		a = T1 + T2;

		j++;
	} while (j < 64);

	/* Compute the current intermediate hash value */
	context->state[0] += a;
	context->state[1] += b;
	context->state[2] += c;
	context->state[3] += d;
	context->state[4] += e;
	context->state[5] += f;
	context->state[6] += g;
	context->state[7] += h;

	/* Clean up */
	a = b = c = d = e = f = g = h = T1 = T2 = 0;
}

#endif /* SHA2_UNROLL_TRANSFORM */

int
SHA256_Update(SHA256_CTX *context, const uint8_t *data, size_t len)
{
	unsigned int	freespace, usedspace;

	if (len == 0) {
		/* Calling with no data is valid - we do nothing */
		return 1;
	}

	usedspace = (unsigned int)((context->bitcount >> 3) %
				    SHA256_BLOCK_LENGTH);
	if (usedspace > 0) {
		/* Calculate how much free space is available in the buffer */
		freespace = SHA256_BLOCK_LENGTH - usedspace;

		if (len >= freespace) {
			/* Fill the buffer completely and process it */
			memcpy(&context->buffer[usedspace], data,
			    (size_t)(freespace));
			context->bitcount += freespace << 3;
			len -= freespace;
			data += freespace;
			SHA256_Transform(context,
			    (uint32_t *)(void *)context->buffer);
		} else {
			/* The buffer is not yet full */
			memcpy(&context->buffer[usedspace], data, len);
			context->bitcount += len << 3;
			/* Clean up: */
			usedspace = freespace = 0;
			return 1;
		}
	}
	/*
	 * Process as many complete blocks as possible.
	 *
	 * Check alignment of the data pointer. If it is 32bit aligned,
	 * SHA256_Transform can be called directly on the data stream,
	 * otherwise enforce the alignment by copy into the buffer.
	 */
	if ((uintptr_t)data % 4 == 0) {
		while (len >= SHA256_BLOCK_LENGTH) {
			SHA256_Transform(context,
			    (const uint32_t *)(const void *)data);
			context->bitcount += SHA256_BLOCK_LENGTH << 3;
			len -= SHA256_BLOCK_LENGTH;
			data += SHA256_BLOCK_LENGTH;
		}
	} else {
		while (len >= SHA256_BLOCK_LENGTH) {
			memcpy(context->buffer, data, SHA256_BLOCK_LENGTH);
			SHA256_Transform(context,
			    (const uint32_t *)(const void *)context->buffer);
			context->bitcount += SHA256_BLOCK_LENGTH << 3;
			len -= SHA256_BLOCK_LENGTH;
			data += SHA256_BLOCK_LENGTH;
		}
	}
	if (len > 0) {
		/* There's left-overs, so save 'em */
		memcpy(context->buffer, data, len);
		context->bitcount += len << 3;
	}
	/* Clean up: */
	usedspace = freespace = 0;

	return 1;
}

static int
SHA224_256_Final(uint8_t digest[], SHA256_CTX *context, size_t len)
{
	uint32_t	*d = (void *)digest;
	unsigned int	usedspace;
	size_t i;

	/* If no digest buffer is passed, we don't bother doing this: */
	if (digest != NULL) {
		usedspace = (unsigned int)((context->bitcount >> 3) %
		    SHA256_BLOCK_LENGTH);
		context->bitcount = htobe64(context->bitcount);
		if (usedspace > 0) {
			/* Begin padding with a 1 bit: */
			context->buffer[usedspace++] = 0x80;

			if (usedspace <= SHA256_SHORT_BLOCK_LENGTH) {
				/* Set-up for the last transform: */
				memset(&context->buffer[usedspace], 0,
				    (size_t)(SHA256_SHORT_BLOCK_LENGTH -
				    usedspace));
			} else {
				if (usedspace < SHA256_BLOCK_LENGTH) {
					memset(&context->buffer[usedspace], 0,
					    (size_t)(SHA256_BLOCK_LENGTH -
					    usedspace));
				}
				/* Do second-to-last transform: */
				SHA256_Transform(context,
				    (uint32_t *)(void *)context->buffer);

				/* And set-up for the last transform: */
				memset(context->buffer, 0,
				    (size_t)(SHA256_SHORT_BLOCK_LENGTH));
			}
		} else {
			/* Set-up for the last transform: */
			memset(context->buffer, 0,
			    (size_t)(SHA256_SHORT_BLOCK_LENGTH));

			/* Begin padding with a 1 bit: */
			*context->buffer = 0x80;
		}
		/* Set the bit count: */
		memcpy(&context->buffer[SHA256_SHORT_BLOCK_LENGTH],
		    &context->bitcount, sizeof(context->bitcount));

		/* Final transform: */
		SHA256_Transform(context, (uint32_t *)(void *)context->buffer);

		for (i = 0; i < len / 4; i++)
			d[i] = htobe32(context->state[i]);
	}

	/* Clean up state data: */
	memset(context, 0, sizeof(*context));
	usedspace = 0;

	return 1;
}

static int
SHA256_Final(uint8_t digest[], SHA256_CTX *context)
{
	return SHA224_256_Final(digest, context, SHA256_DIGEST_LENGTH);
}

/*
 * Constant used by SHA256/384/512_End() functions for converting the
 * digest to a readable hexadecimal character string:
 */
static const char sha2_hex_digits[] = "0123456789abcdef";

char *
SHA256_End(SHA256_CTX *ctx, uint8_t *buffer)
{
	uint8_t digest[SHA256_DIGEST_LENGTH], *d = digest;
	uint8_t *ret;
	int  i;

	/* Sanity check: */
	assert(ctx != NULL);

	if ((ret = buffer) != NULL) {
		SHA256_Final(digest, ctx);

		for (i = 0; i < SHA256_DIGEST_LENGTH; i++) {
			*buffer++ = (uint8_t)sha2_hex_digits[(*d & 0xf0) >> 4];
			*buffer++ = (uint8_t)sha2_hex_digits[*d & 0x0f];
			d++;
		}
		*buffer = (char) 0;
	} else {
		(void)memset(ctx, 0, sizeof(SHA256_CTX));
	}
	(void)memset(digest, 0, SHA256_DIGEST_LENGTH);
	return (char *)ret;
}
