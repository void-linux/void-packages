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

/* Default root PATH for xbps to store metadata info. */
#define XBPS_META_PATH		"/var/db/xbps"

/* Filename for the repositories plist file. */
#define XBPS_REPOLIST		"repositories.plist"

/* Filename of the package index plist for a repository. */
#define XBPS_PKGINDEX		"pkg-index.plist"

/* Filename of the packages register. */
#define XBPS_REGPKGDB		"regpkgdb.plist"

#include "cmpver.h"
#include "fexec.h"
#include "humanize_number.h"
#include "install.h"
#include "plist.h"
#include "remove.h"
#include "repository.h"
#include "sha256.h"
#include "util.h"
#include "queue.h"

#endif /* !_XBPS_API_H_ */
