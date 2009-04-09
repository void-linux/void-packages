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

#ifndef _XBPS_API_H_
#define _XBPS_API_H_

#include <stdio.h>
#include <inttypes.h>
#define NDEBUG
#include <assert.h>

#include <prop/proplib.h>
#include <archive.h>
#include <archive_entry.h>

#include "sha256.h"
#include "queue.h"

/* Default root PATH for xbps to store metadata info. */
#define XBPS_META_PATH		"/var/db/xbps"

/* Filename for the repositories plist file. */
#define XBPS_REPOLIST		"repositories.plist"

/* Filename of the package index plist for a repository. */
#define XBPS_PKGINDEX		"pkg-index.plist"

/* Filename of the packages register. */
#define XBPS_REGPKGDB		"regpkgdb.plist"

/* Filename of the package properties plist file. */
#define XBPS_PKGPROPS		"props.plist"
#define XBPS_PKGFILES		"files.plist"

/* Current version of the package index format. */
#define XBPS_PKGINDEX_VERSION	"1.0"

/* Verbose messages */
#define XBPS_VERBOSE		0x00000001

/* from lib/cmpver.c */
int		xbps_cmpver_packages(const char *, const char *);
int		xbps_cmpver_versions(const char *, const char *);

/* From lib/fexec.c */
int		xbps_file_exec(const char *, ...);
int		xbps_file_exec_skipempty(const char *, ...);
int		xbps_file_chdir_exec(const char *, const char *, ...);

/* From lib/humanize_number.c */
#define HN_DECIMAL		0x01
#define HN_NOSPACE		0x02
#define HN_B			0x04
#define HN_DIVISOR_1000		0x08
#define HN_GETSCALE		0x10
#define HN_AUTOSCALE		0x20

int		xbps_humanize_number(char *, size_t, int64_t, const char *,
				     int, int);

/* From lib/findpkg.c */
int		xbps_prepare_pkg(const char *);
prop_dictionary_t	xbps_get_pkg_props(const char *);

/* From lib/register.c */
int		xbps_register_pkg(prop_dictionary_t, bool, bool);

/* From lib/requiredby.c */
int		xbps_requiredby_pkg_add(prop_array_t, prop_dictionary_t);
int		xbps_requiredby_pkg_remove(const char *);

/* From lib/unpack.c */
int		xbps_unpack_binary_pkg(prop_dictionary_t);

/* From lib/depends.c */
int		xbps_find_deps_in_pkg(prop_dictionary_t, prop_dictionary_t,
				      prop_object_iterator_t);

/* From lib/plist.c */
bool		xbps_add_obj_to_dict(prop_dictionary_t, prop_object_t,
				     const char *);
bool		xbps_add_obj_to_array(prop_array_t, prop_object_t);

int 		xbps_callback_array_iter_in_dict(prop_dictionary_t,
			const char *, int (*fn)(prop_object_t, void *, bool *),
			void *);
int 		xbps_callback_array_iter_in_repolist(int (*fn)(prop_object_t,
			void *, bool *), void *);

prop_dictionary_t	xbps_find_pkg_in_dict(prop_dictionary_t,
					      const char *, const char *);
prop_dictionary_t	xbps_find_pkg_from_plist(const char *, const char *);
prop_dictionary_t 	xbps_find_pkg_installed_from_plist(const char *);
bool 		xbps_find_string_in_array(prop_array_t, const char *);

prop_object_iterator_t	xbps_get_array_iter_from_dict(prop_dictionary_t,
						      const char *);

int 		xbps_remove_pkg_dict_from_file(const char *, const char *);
int		xbps_remove_pkg_from_dict(prop_dictionary_t, const char *,
					  const char *);
int		xbps_remove_string_from_array(prop_array_t, const char *);

/* From lib/remove.c */
int		xbps_remove_binary_pkg(const char *, bool);
int		xbps_unregister_pkg(const char *);

/* From lib/repository.c */
int		xbps_register_repository(const char *);
int		xbps_unregister_repository(const char *);

/* From lib/sortdeps.c */
int		xbps_sort_pkg_deps(prop_dictionary_t);

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
bool		xbps_yesno(const char *, ...);
bool		xbps_noyes(const char *, ...);

/* From lib/orphans.c */
prop_array_t	xbps_find_orphan_packages(void);

#endif /* !_XBPS_API_H_ */
