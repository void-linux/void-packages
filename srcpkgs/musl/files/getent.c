/*-
 * Copyright (c) 2004-2006 The NetBSD Foundation, Inc.
 * All rights reserved.
 *
 * This code is derived from software contributed to The NetBSD Foundation
 * by Luke Mewburn.
 * Timo Teräs cleaned up the code for use in Alpine Linux with musl libc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE NETBSD FOUNDATION, INC. AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <sys/socket.h>
#include <sys/param.h>
#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <netdb.h>
#include <pwd.h>
#include <grp.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <paths.h>
#include <err.h>

#include <arpa/inet.h>
#include <arpa/nameser.h>

#include <net/if.h>
#include <net/ethernet.h>
#include <netinet/ether.h>
#include <netinet/in.h>

enum {
	RV_OK		= 0,
	RV_USAGE	= 1,
	RV_NOTFOUND	= 2,
	RV_NOENUM	= 3
};

static int usage(const char *);

static int parsenum(const char *word, unsigned long *result)
{
	unsigned long	num;
	char		*ep;

	if (!isdigit((unsigned char)word[0]))
		return 0;
	errno = 0;
	num = strtoul(word, &ep, 10);
	if (num == ULONG_MAX && errno == ERANGE)
		return 0;
	if (*ep != '\0')
		return 0;
	*result = num;
	return 1;
}

/*
 * printfmtstrings --
 *	vprintf(format, ...),
 *	then the aliases (beginning with prefix, separated by sep),
 *	then a newline
 */
__attribute__ ((format (printf, 4, 5)))
static void printfmtstrings(char *strings[], const char *prefix, const char *sep,
	const char *fmt, ...)
{
	va_list		ap;
	const char	*curpref;
	size_t		i;

	va_start(ap, fmt);
	(void)vprintf(fmt, ap);
	va_end(ap);

	curpref = prefix;
	for (i = 0; strings[i] != NULL; i++) {
		(void)printf("%s%s", curpref, strings[i]);
		curpref = sep;
	}
	(void)printf("\n");
}

static int ethers(int argc, char *argv[])
{
	char		hostname[MAXHOSTNAMELEN + 1], *hp;
	struct ether_addr ea, *eap;
	int		i, rv;

	if (argc == 2) {
		warnx("Enumeration not supported on ethers");
		return RV_NOENUM;
	}

	rv = RV_OK;
	for (i = 2; i < argc; i++) {
		if ((eap = ether_aton(argv[i])) == NULL) {
			eap = &ea;
			hp = argv[i];
			if (ether_hostton(hp, eap) != 0) {
				rv = RV_NOTFOUND;
				break;
			}
		} else {
			hp = hostname;
			if (ether_ntohost(hp, eap) != 0) {
				rv = RV_NOTFOUND;
				break;
			}
		}
		(void)printf("%-17s  %s\n", ether_ntoa(eap), hp);
	}
	return rv;
}

static void groupprint(const struct group *gr)
{
	printfmtstrings(gr->gr_mem, ":", ",", "%s:%s:%u",
			gr->gr_name, gr->gr_passwd, gr->gr_gid);
}

static int group(int argc, char *argv[])
{
	struct group	*gr;
	unsigned long	id;
	int		i, rv;

	rv = RV_OK;
	if (argc == 2) {
		while ((gr = getgrent()) != NULL)
			groupprint(gr);
	} else {
		for (i = 2; i < argc; i++) {
			if (parsenum(argv[i], &id))
				gr = getgrgid((gid_t)id);
			else
				gr = getgrnam(argv[i]);
			if (gr == NULL) {
				rv = RV_NOTFOUND;
				break;
			}
			groupprint(gr);
		}
	}
	endgrent();
	return rv;
}

static void hostsprint(const struct hostent *he)
{
	char	buf[INET6_ADDRSTRLEN];

	if (inet_ntop(he->h_addrtype, he->h_addr, buf, sizeof(buf)) == NULL)
		(void)strlcpy(buf, "# unknown", sizeof(buf));
	printfmtstrings(he->h_aliases, "  ", " ", "%-16s  %s", buf, he->h_name);
}

static int hosts(int argc, char *argv[])
{
	struct hostent	*he;
	char		addr[IN6ADDRSZ];
	int		i, rv;

	sethostent(1);
	rv = RV_OK;
	if (argc == 2) {
		while ((he = gethostent()) != NULL)
			hostsprint(he);
	} else {
		for (i = 2; i < argc; i++) {
			if (inet_pton(AF_INET6, argv[i], (void *)addr) > 0)
				he = gethostbyaddr(addr, IN6ADDRSZ, AF_INET6);
			else if (inet_pton(AF_INET, argv[i], (void *)addr) > 0)
				he = gethostbyaddr(addr, INADDRSZ, AF_INET);
			else
				he = gethostbyname(argv[i]);
			if (he == NULL) {
				rv = RV_NOTFOUND;
				break;
			}
			hostsprint(he);
		}
	}
	endhostent();
	return rv;
}

static void networksprint(const struct netent *ne)
{
	char		buf[INET6_ADDRSTRLEN];
	struct	in_addr	ianet;

	ianet = inet_makeaddr(ne->n_net, 0);
	if (inet_ntop(ne->n_addrtype, &ianet, buf, sizeof(buf)) == NULL)
		(void)strlcpy(buf, "# unknown", sizeof(buf));
	printfmtstrings(ne->n_aliases, "  ", " ", "%-16s  %s", ne->n_name, buf);
}

static int networks(int argc, char *argv[])
{
	struct netent	*ne;
	in_addr_t	net;
	int		i, rv;

	setnetent(1);
	rv = RV_OK;
	if (argc == 2) {
		while ((ne = getnetent()) != NULL)
			networksprint(ne);
	} else {
		for (i = 2; i < argc; i++) {
			net = inet_network(argv[i]);
			if (net != INADDR_NONE)
				ne = getnetbyaddr(net, AF_INET);
			else
				ne = getnetbyname(argv[i]);
			if (ne == NULL) {
				rv = RV_NOTFOUND;
				break;
			}
			networksprint(ne);
		}
	}
	endnetent();
	return rv;
}

static void passwdprint(struct passwd *pw)
{
	(void)printf("%s:%s:%u:%u:%s:%s:%s\n",
		pw->pw_name, pw->pw_passwd, pw->pw_uid,
		pw->pw_gid, pw->pw_gecos, pw->pw_dir, pw->pw_shell);
}

static int passwd(int argc, char *argv[])
{
	struct passwd	*pw;
	unsigned long	id;
	int		i, rv;

	rv = RV_OK;
	if (argc == 2) {
		while ((pw = getpwent()) != NULL)
			passwdprint(pw);
	} else {
		for (i = 2; i < argc; i++) {
			if (parsenum(argv[i], &id))
				pw = getpwuid((uid_t)id);
			else
				pw = getpwnam(argv[i]);
			if (pw == NULL) {
				rv = RV_NOTFOUND;
				break;
			}
			passwdprint(pw);
		}
	}
	endpwent();
	return rv;
}

static void protocolsprint(struct protoent *pe)
{
	printfmtstrings(pe->p_aliases, "  ", " ",
			"%-16s  %5d", pe->p_name, pe->p_proto);
}

static int protocols(int argc, char *argv[])
{
	struct protoent	*pe;
	unsigned long	id;
	int		i, rv;

	setprotoent(1);
	rv = RV_OK;
	if (argc == 2) {
		while ((pe = getprotoent()) != NULL)
			protocolsprint(pe);
	} else {
		for (i = 2; i < argc; i++) {
			if (parsenum(argv[i], &id))
				pe = getprotobynumber((int)id);
			else
				pe = getprotobyname(argv[i]);
			if (pe == NULL) {
				rv = RV_NOTFOUND;
				break;
			}
			protocolsprint(pe);
		}
	}
	endprotoent();
	return rv;
}

static void servicesprint(struct servent *se)
{
	printfmtstrings(se->s_aliases, "  ", " ",
			"%-16s  %5d/%s",
			se->s_name, ntohs(se->s_port), se->s_proto);

}

static int services(int argc, char *argv[])
{
	struct servent	*se;
	unsigned long	id;
	char		*proto;
	int		i, rv;

	setservent(1);
	rv = RV_OK;
	if (argc == 2) {
		while ((se = getservent()) != NULL)
			servicesprint(se);
	} else {
		for (i = 2; i < argc; i++) {
			proto = strchr(argv[i], '/');
			if (proto != NULL)
				*proto++ = '\0';
			if (parsenum(argv[i], &id))
				se = getservbyport(htons(id), proto);
			else
				se = getservbyname(argv[i], proto);
			if (se == NULL) {
				rv = RV_NOTFOUND;
				break;
			}
			servicesprint(se);
		}
	}
	endservent();
	return rv;
}

static int shells(int argc, char *argv[])
{
	const char	*sh;
	int		i, rv;

	setusershell();
	rv = RV_OK;
	if (argc == 2) {
		while ((sh = getusershell()) != NULL)
			(void)printf("%s\n", sh);
	} else {
		for (i = 2; i < argc; i++) {
			setusershell();
			while ((sh = getusershell()) != NULL) {
				if (strcmp(sh, argv[i]) == 0) {
					(void)printf("%s\n", sh);
					break;
				}
			}
			if (sh == NULL) {
				rv = RV_NOTFOUND;
				break;
			}
		}
	}
	endusershell();
	return rv;
}

static struct getentdb {
	const char	*name;
	int		(*callback)(int, char *[]);
} databases[] = {
	{	"ethers",	ethers,		},
	{	"group",	group,		},
	{	"hosts",	hosts,		},
	{	"networks",	networks,	},
	{	"passwd",	passwd,		},
	{	"protocols",	protocols,	},
	{	"services",	services,	},
	{	"shells",	shells,		},

	{	NULL,		NULL,		},
};

static int usage(const char *arg0)
{
	struct getentdb	*curdb;
	size_t i;

	(void)fprintf(stderr, "Usage: %s database [key ...]\n", arg0);
	(void)fprintf(stderr, "\tdatabase may be one of:");
	for (i = 0, curdb = databases; curdb->name != NULL; curdb++, i++) {
		if (i % 7 == 0)
			(void)fputs("\n\t\t", stderr);
		(void)fprintf(stderr, "%s%s", i % 7 == 0 ? "" : " ",
		    curdb->name);
	}
	(void)fprintf(stderr, "\n");
	exit(RV_USAGE);
	/* NOTREACHED */
}

int
main(int argc, char *argv[])
{
	struct getentdb	*curdb;

	if (argc < 2)
		usage(argv[0]);
	for (curdb = databases; curdb->name != NULL; curdb++)
		if (strcmp(curdb->name, argv[1]) == 0)
			return (*curdb->callback)(argc, argv);

	warn("Unknown database `%s'", argv[1]);
	usage(argv[0]);
	/* NOTREACHED */
}
