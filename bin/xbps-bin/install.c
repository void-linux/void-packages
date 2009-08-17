/*-
 * Copyright (c) 2009 Juan Romero Pardines.
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

#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <xbps_api.h>
#include "defs.h"

struct transaction {
	prop_dictionary_t dict;
	prop_object_iterator_t iter;
	const char *originpkgname;
	bool force;
};

static void	cleanup(int);
static int	exec_transaction(struct transaction *);
static void	show_missing_deps(prop_dictionary_t, const char *);
static int	show_missing_dep_cb(prop_object_t, void *, bool *);
static void	show_package_list(prop_object_iterator_t, const char *);

static void
show_missing_deps(prop_dictionary_t d, const char *pkgname)
{
	printf("Unable to locate some required packages for %s:\n",
	    pkgname);
	(void)xbps_callback_array_iter_in_dict(d, "missing_deps",
	    show_missing_dep_cb, NULL);
}

static int
show_missing_dep_cb(prop_object_t obj, void *arg, bool *loop_done)
{
	const char *pkgname, *version;

        (void)arg;
        (void)loop_done;

	prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
	prop_dictionary_get_cstring_nocopy(obj, "version", &version);
	if (pkgname && version) {
		printf("  * Missing binary package for: %s >= %s\n",
		    pkgname, version);
		return 0;
	}

	return EINVAL;
}

static int
check_pkg_hashes(prop_object_iterator_t iter)
{
	prop_object_t obj;
	const char *pkgname, *repoloc, *filename;
	int rv = 0;
	pkg_state_t state = 0;

	printf("Checking binary package file(s) integrity...\n");
	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
		state = 0;
		if (xbps_get_pkg_state_dictionary(obj, &state) != 0)
			return EINVAL;

		if (state == XBPS_PKG_STATE_UNPACKED)
			continue;

		prop_dictionary_get_cstring_nocopy(obj, "repository", &repoloc);
		prop_dictionary_get_cstring_nocopy(obj, "filename", &filename);
		rv = xbps_check_pkg_file_hash(obj, repoloc);
		if (rv != 0 && rv != ERANGE) {
			printf("Unexpected error while checking hash for "
			    "%s (%s)\n", filename, strerror(rv));
			return -1;
		} else if (rv != 0 && rv == ERANGE) {
			printf("Hash mismatch for %s, exiting.\n",
			    filename);
			return -1;
		}
	}
	prop_object_iterator_reset(iter);

	return 0;
}

static void
show_package_list(prop_object_iterator_t iter, const char *match)
{
	prop_object_t obj;
	size_t cols = 0;
	const char *pkgname, *version, *tract;
	bool first = false;

	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
		prop_dictionary_get_cstring_nocopy(obj, "version", &version);
		prop_dictionary_get_cstring_nocopy(obj, "trans-action", &tract);
		if (strcmp(match, tract))
			continue;

		cols += strlen(pkgname) + strlen(version) + 4;
		if (cols <= 80) {
			if (first == false) {
				printf("  ");
				first = true;
			}
		} else {
			printf("\n  ");
			cols = strlen(pkgname) + strlen(version) + 4;
		}
		printf("%s-%s ", pkgname, version);
	}
	prop_object_iterator_reset(iter);
}

static int
show_transaction_sizes(prop_object_iterator_t iter)
{
	prop_object_t obj;
	uint64_t tsize = 0, dlsize = 0, instsize = 0;
	const char *tract;
	char size[64];
	bool trans_inst = false, trans_up = false;

	/*
	 * Iterate over the list of packages that are going to be
	 * installed and check the file hash.
	 */
	while ((obj = prop_object_iterator_next(iter)) != NULL) {
		prop_dictionary_get_uint64(obj, "filename-size", &tsize);
		dlsize += tsize;
		tsize = 0;
		prop_dictionary_get_uint64(obj, "installed_size", &tsize);
		instsize += tsize;
		tsize = 0;
	}
	prop_object_iterator_reset(iter);

	while ((obj = prop_object_iterator_next(iter))) {
		prop_dictionary_get_cstring_nocopy(obj, "trans-action", &tract);
		if (strcmp(tract, "install") == 0)
			trans_inst = true;
		else if (strcmp(tract, "update") == 0)
			trans_up = true;
	}
	prop_object_iterator_reset(iter);

	/*
	 * Show the list of packages that will be installed.
	 */
	if (trans_inst) {
		printf("The following packages will be installed:\n\n");
		show_package_list(iter, "install");
		printf("\n\n");
	}
	if (trans_up) {
		printf("The following packages will be updated:\n\n");
		show_package_list(iter, "update");
		printf("\n\n");
	}

	/*
	 * Show total download/installed size for all required packages.
	 */
	if (xbps_humanize_number(size, 5, (int64_t)dlsize,
	    "", HN_AUTOSCALE, HN_NOSPACE) == -1) {
		printf("error: humanize_number returns %s\n",
		    strerror(errno));
		return -1;
	}
	printf("Total download size: %s\n", size);
	if (xbps_humanize_number(size, 5, (int64_t)instsize,
	    "", HN_AUTOSCALE, HN_NOSPACE) == -1) {
		printf("error: humanize_number2 returns %s\n",
		    strerror(errno));
		return -1;
	}
	printf("Total installed size: %s\n\n", size);

	return 0;
}

void
xbps_install_pkg(const char *pkg, bool force, bool update)
{
	struct transaction *trans;
	prop_dictionary_t pkgd;
	prop_array_t array;
	int rv = 0;

	/*
	 * Find all required pkgs and sort the package transaction.
	 */
	pkgd = xbps_find_pkg_installed_from_plist(pkg);
	if (update) {
		if (pkgd) {
			if ((rv = xbps_find_new_pkg(pkg, pkgd)) == 0) {
				printf("Package '%s' is up to date.\n", pkg);
				prop_object_release(pkgd);
				cleanup(rv);
			}
			prop_object_release(pkgd);
		} else {
			printf("Package '%s' not installed.\n", pkg);
			cleanup(rv);
		}
	} else {
		if (pkgd) {
			printf("Package '%s' is already installed.\n", pkg);
			prop_object_release(pkgd);
			cleanup(rv);
		}
		rv = xbps_prepare_pkg(pkg);
		if (rv != 0 && rv == EAGAIN) {
			printf("unable to locate %s in repository pool.", pkg);
			cleanup(rv);
		} else if (rv != 0 && rv != ENOENT) {
			printf("unexpected error: %s", strerror(rv));
			cleanup(rv);
		}
	}

	trans = calloc(1, sizeof(struct transaction));
	if (trans == NULL)
		goto out;

	trans->dict = xbps_get_pkg_props();
	if (trans->dict == NULL) {
		printf("error: unexistent props dictionary!\n");
		goto out1;
	}

	/*
	 * Bail out if there are unresolved deps.
	 */
	array = prop_dictionary_get(trans->dict, "missing_deps");
	if (prop_array_count(array) > 0) {
		show_missing_deps(trans->dict, pkg);
		goto out2;
	}

	prop_dictionary_get_cstring_nocopy(trans->dict,
	     "origin", &trans->originpkgname);

	/*
	 * It's time to run the transaction!
	 */
	trans->iter = xbps_get_array_iter_from_dict(trans->dict, "packages");
	if (trans->iter == NULL) {
		printf("error: allocating array mem! (%s)",
		    strerror(errno));
		goto out2;
	}

	trans->force = force;
	rv = exec_transaction(trans);

	prop_object_iterator_release(trans->iter);
out2:
	prop_object_release(trans->dict);
out1:
	free(trans);
out:
	cleanup(rv);
}

static int
exec_transaction(struct transaction *trans)
{
	prop_dictionary_t instpkgd;
	prop_object_t obj;
	const char *pkgname, *version, *instver, *filename, *tract;
	int rv = 0;
	bool essential, isdep, autoinst;
	pkg_state_t state = 0;

	assert(trans != NULL);
	assert(trans->dict != NULL);
	assert(trans->iter != NULL);

	essential = isdep = autoinst = false;
	/*
	 * Show download/installed size for the transaction.
	 */
	rv = show_transaction_sizes(trans->iter);
	if (rv != 0)
		return rv;

	/*
	 * Ask interactively (if -f not set).
	 */
	if (trans->force == false) {
		if (xbps_noyes("Do you want to continue?") == false) {
			printf("Aborting!\n");
			return 0;
		}
	}

	/*
	 * Check the SHA256 hash for all required packages.
	 */
	if ((rv = check_pkg_hashes(trans->iter)) != 0)
		return rv;

	/*
	 * Iterate over the transaction dictionary.
	 */
	while ((obj = prop_object_iterator_next(trans->iter)) != NULL) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
		prop_dictionary_get_cstring_nocopy(obj, "version", &version);
		prop_dictionary_get_bool(obj, "essential", &essential);
		prop_dictionary_get_cstring_nocopy(obj, "filename", &filename);
		prop_dictionary_get_cstring_nocopy(obj, "trans-action", &tract);

		if (trans->originpkgname &&
		    strcmp(trans->originpkgname, pkgname))
			isdep = true;

		/*
		 * If dependency is already unpacked skip this phase.
		 */
		state = 0;
		if (xbps_get_pkg_state_dictionary(obj, &state) != 0)
			return EINVAL;

		if (state == XBPS_PKG_STATE_UNPACKED)
			continue;

		if (strcmp(tract, "update") == 0) {
			instpkgd = xbps_find_pkg_installed_from_plist(pkgname);
			if (instpkgd == NULL) {
				printf("error: unable to find %s installed "
				    "dict!\n", pkgname);
				return EINVAL;
			}

			prop_dictionary_get_cstring_nocopy(instpkgd,
			    "version", &instver);
			autoinst = false;
			prop_dictionary_get_bool(instpkgd, "automatic-install",
			    &autoinst);
			isdep = autoinst;
			prop_object_release(instpkgd);

			/*
			 * If this package is not 'essential', just remove
			 * the old package and install the new one. Otherwise
			 * we just overwrite the files.
			 */
			if (essential == false) {
				rv = xbps_remove_pkg(pkgname, version, true);
				if (rv != 0) {
					printf("error: removing %s-%s (%s)\n",
					    pkgname, instver, strerror(rv));
					return rv;
				}
			}
		}
		/*
		 * Unpack binary package.
		 */
		printf("Unpacking %s-%s (from .../%s) ...\n", pkgname, version,
		    filename);
		if ((rv = xbps_unpack_binary_pkg(obj, essential)) != 0) {
			printf("error: unpacking %s-%s (%s)\n", pkgname,
			    version, strerror(rv));
			return rv;
		}
		/*
		 * Register binary package.
		 */
		if ((rv = xbps_register_pkg(obj, isdep)) != 0) {
			printf("error: registering %s-%s! (%s)\n",
			    pkgname, version, strerror(rv));
			return rv;
		}
		isdep = false;
		/*
		 * Set package state to unpacked in the transaction
		 * dictionary.
		 */
		if ((rv = xbps_set_pkg_state_dictionary(obj,
		    XBPS_PKG_STATE_UNPACKED)) != 0)
			return rv;
	}
	prop_object_iterator_reset(trans->iter);
	/*
	 * Configure all unpacked packages.
	 */
	while ((obj = prop_object_iterator_next(trans->iter)) != NULL) {
		prop_dictionary_get_cstring_nocopy(obj, "pkgname", &pkgname);
		if ((rv = xbps_configure_pkg(pkgname)) != 0) {
			printf("Error configuring package %s (%s)\n",
			    pkgname, strerror(rv));
			return rv;
		}
	}

	return 0;
}

void
xbps_autoupdate_pkgs(bool force)
{
	struct transaction *trans;
	int rv = 0;

	/*
	 * Find new package versions.
	 */
	if ((rv = xbps_find_new_packages()) != 0) {
		if (rv == ENOENT) {
			printf("No packages currently registered.\n");
			cleanup(0);
		}
		goto out;
	}

	/*
	 * Prepare transaction data.
	 */
	trans = calloc(1, sizeof(struct transaction));
	if (trans == NULL)
		goto out;

	/*
	 * Get package transaction dictionary.
	 */
	trans->dict = xbps_get_pkg_props();
	if (trans->dict == NULL) {
		if (errno == 0) {
			printf("All packages are up-to-date.\n");
			goto out;
		}
		printf("Error while checking for new pkgs: %s\n",
		    strerror(errno));
		goto out1;
	}
	/*
	 * Sort the package transaction dictionary.
	 */
	if ((rv = xbps_sort_pkg_deps(trans->dict)) != 0) {
		printf("Error while sorting packages: %s\n",
		    strerror(rv));
		goto out2;
	}

	/*
	 * It's time to run the transaction!
	 */
	trans->iter = xbps_get_array_iter_from_dict(trans->dict, "packages");
	if (trans->iter == NULL) {
		printf("error: allocating array mem! (%s)\n", strerror(errno));
		goto out2;
	}

	trans->force = force;
	rv = exec_transaction(trans);

	prop_object_iterator_release(trans->iter);
out2:
	prop_object_release(trans->dict);
out1:
	free(trans);
out:
	cleanup(rv);
}

static void
cleanup(int rv)
{
	xbps_release_repolist_data();
	xbps_release_regpkgdb_dict();
	exit(rv == 0 ? EXIT_SUCCESS : EXIT_FAILURE);
}
