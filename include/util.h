/*-
 * Copyright (c) 2008-2009 Juan Romero Pardines.
 * All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef _XBPS_UTIL_H_
#define _XBPS_UTIL_H_

/* From lib/util.c */
char *		xbps_xasprintf(const char *, ...);
char *		xbps_get_file_hash(const char *);
int		xbps_check_file_hash(const char *, const char *);
int		xbps_check_pkg_file_hash(prop_dictionary_t, const char *);
int		xbps_check_is_installed_pkg(const char *);
bool		xbps_check_is_installed_pkgname(const char *);
char *		xbps_get_pkg_index_plist(const char *);
char *		xbps_get_pkg_name(const char *);
const char *	xbps_get_pkg_version(const char *);
bool		xbps_pkg_has_rundeps(prop_dictionary_t);
void		xbps_set_rootdir(const char *);
const char *	xbps_get_rootdir(void);
void		xbps_set_flags(int);
int		xbps_get_flags(void);

/* From lib/orphans.c */
prop_array_t	xbps_find_orphan_packages(void);

#endif /* !_XBPS_UTIL_H_ */
