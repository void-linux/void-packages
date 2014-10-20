/* c_rehash.c - C implementation based on the Perl and shell versions
 *
 * Copyright (c) 2013 Timo Teräs <timo.teras@iki.fi>
 * All rights reserved.
 *
 * This software is licensed under the MIT License.
 * Full license available at: http://opensource.org/licenses/MIT
 */

#define _POSIX_C_SOURCE 200809L
#define _GNU_SOURCE
#include <ctype.h>
#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <fnmatch.h>
#include <sys/stat.h>

#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/x509.h>

#define countof(x) (sizeof(x) / sizeof(x[0]))

struct hash_info {
	struct hash_info *next;
	int type;
	unsigned long hash;
	unsigned char digest[EVP_MAX_MD_SIZE];
};

enum Type {
	TYPE_CERT = 0,
	TYPE_CRL,
	MAX_TYPES,
};

static const EVP_MD *evpmd;
static int evpmdsize;
static const char *prefixes[MAX_TYPES] = { "", "r" };
static struct hash_info *hash_table[257];

static int get_link_id(int type, unsigned long hash, unsigned char *digest)
{
	unsigned int bucket = hash % countof(hash_table);
	struct hash_info *hi;
	int count = 0;

	for (hi = hash_table[bucket]; hi; hi = hi->next) {
		if (hi->type != type || hi->hash != hash)
			continue;
		if (memcmp(digest, hi->digest, evpmdsize) == 0)
			return -1;
		count++;
	}

	hi = malloc(sizeof(*hi));
	hi->next = hash_table[bucket];
	hi->type = type;
	hi->hash = hash;
	memcpy(hi->digest, digest, evpmdsize);
	hash_table[bucket] = hi;

	return count;
}

static int link_file(int dirfd, const char *filename, int type, unsigned long hash, unsigned char *digest)
{
	char linkfn[32];
	int id;

	id = get_link_id(type, hash, digest);
	if (id < 0) {
		fprintf(stderr, "WARNING: Skipping duplicate certificate in file %s\n",
			filename);
		return -1;
	}

	snprintf(linkfn, sizeof(linkfn),
		 "%08lx.%s%d", hash, prefixes[type], id);
	fprintf(stdout, "%s => %s\n", linkfn, filename);
	if (symlinkat(filename, dirfd, linkfn) < 0)
		perror(linkfn);

	return 0;
}

static BIO *BIO_openat(int dirfd, const char *filename)
{
	FILE *fp;
	BIO *bio;
	int fd;

	fd = openat(dirfd, filename, O_RDONLY);
	if (fd < 0) {
		perror(filename);
		return NULL;
	}
	fp = fdopen(fd, "r");
	if (fp == NULL) {
		close(fd);
		return NULL;
	}
	bio = BIO_new_fp(fp, BIO_CLOSE);
	if (!bio) {
		fclose(fp);
		return NULL;
	}
	return bio;
}

static int hash_file(int dirfd, const char *filename)
{
	STACK_OF(X509_INFO) *inf;
	X509_INFO *x;
	BIO *b;
	int i, count = 0;
	unsigned char digest[EVP_MAX_MD_SIZE];

	b = BIO_openat(dirfd, filename);
	if (!b)
		return -1;

	inf = PEM_X509_INFO_read_bio(b, NULL, NULL, NULL);
	BIO_free(b);
	if (!inf)
		return -1;

	for(i = 0; i < sk_X509_INFO_num(inf); i++) {
		x = sk_X509_INFO_value(inf, i);
		if (x->x509) {
			X509_digest(x->x509, evpmd, digest, NULL);
			link_file(dirfd, filename, TYPE_CERT,
				  X509_subject_name_hash(x->x509), digest);
			count++;
		}
		if (x->crl) {
			X509_CRL_digest(x->crl, evpmd, digest, NULL);
			link_file(dirfd, filename, TYPE_CRL,
				  X509_NAME_hash(X509_CRL_get_issuer(x->crl)),
				  digest);
			count++;
		}
	}
	sk_X509_INFO_pop_free(inf, X509_INFO_free);

	if (count == 0) {
		fprintf(stderr,
			"WARNING: %s does not contain a certificate or CRL: skipping\n",
			filename);
	}

	return count;
}

static int is_hash_filename(const char *fn)
{
	int i;

	for (i = 0; i < 8; i++)
		if (!isxdigit(fn[i]))
			return 0;
	if (fn[i++] != '.')
		return 0;
	if (fn[i] == 'r') i++;
	for (; fn[i] != 0; i++)
		if (!isdigit(fn[i]))
			return 0;
	return 1;
}

static int hash_dir(const char *dirname)
{
	struct dirent *de;
	struct stat st;
	int dirfd;
	DIR *d;

	fprintf(stdout, "Doing %s\n", dirname);
	dirfd = open(dirname, O_RDONLY | O_DIRECTORY);
	if (dirfd < 0) {
		perror(dirname);
		return -1;
	}
	d = opendir(dirname);
	if (!d) {
		close(dirfd);
		return -1;
	}
	while ((de = readdir(d)) != NULL) {
		if (fstatat(dirfd, de->d_name, &st, AT_SYMLINK_NOFOLLOW) < 0)
			continue;
		if (!S_ISLNK(st.st_mode))
			continue;
		if (!is_hash_filename(de->d_name))
			continue;

		if (unlinkat(dirfd, de->d_name, 0) < 0)
			perror(de->d_name);
	}

	rewinddir(d);
	while ((de = readdir(d)) != NULL) {
		if (fnmatch("*.pem", de->d_name, FNM_NOESCAPE) == 0)
			hash_file(dirfd, de->d_name);
	}
	closedir(d);

	return 0;
}

int main(int argc, char **argv)
{
	const char *env;
	int i;

	evpmd = EVP_sha1();
	evpmdsize = EVP_MD_size(evpmd);

	if (argc > 1) {
		for (i = 1; i < argc; i++)
			hash_dir(argv[i]);
	} else if ((env = getenv("SSL_CERT_DIR")) != NULL) {
		char *e, *m;
		m = strdup(env);
		for (e = strtok(m, ":"); e != NULL; e = strtok(NULL, ":"))
			hash_dir(e);
		free(m);
	} else {
		hash_dir("/etc/ssl/certs");
	}

	return 0;
}
