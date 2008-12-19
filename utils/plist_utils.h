/*-
 * Copyright (c) 2008 Juan Romero Pardines.
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

#ifndef _XBPS_PLIST_UTILS_H_
#define _XBPS_PLIST_UTILS_H_

/* 
 * Adds an array object with specified key into a dictionary.
 *
 * Arguments:
 * 	- prop_dictionary_t: dictionary to store the array.
 *	- prop_array_t: the array to be stored.
 *	- const char *: the key associated with the array.
 *
 * Returns true on success, false on failure.
 */
bool
xbps_add_array_to_dict(prop_dictionary_t, prop_array_t, const char *);

/*
 * Adds an opaque object into an array.
 *
 * Arguments:
 * 	- prop_array_t: the array storing the object.
 * 	- prop_object_t: the opaque object to be stored.
 *
 * Returns true on success, false on failure.
 */
bool
xbps_add_obj_to_array(prop_array_t, prop_object_t);

/*
 * Finds a package's dictionary into the main dictionary.
 *
 * Arguments:
 * 	- prop_dictionary_t: main dictionary to search the object.
 * 	- 1st const char *key: use a dictionary with that key.
 * 	- 2nd const char *pkgname: string of package name.
 *
 * Returns the package's dictionary object, otherwise NULL.
 */
prop_dictionary_t
xbps_find_pkg_in_dict(prop_dictionary_t, const char *, const char *);

/*
 * Finds a string object in an array.
 *
 * Arguments:
 * 	- prop_array_t: array to search for the string.
 * 	- const char *: string value of the object to be found.
 *
 * Returns true on success, false on failure.
 */
bool
xbps_find_string_in_array(prop_array_t, const char *);

/*
 * Gets an array iterator from a dictionary with a specified key.
 *
 * Arguments:
 * 	- prop_dictionary_t: dictionary to search the array.
 * 	- const char *: key of the array.
 *
 * Returns the object iterator, NULL otherwise.
 */
prop_object_iterator_t
xbps_get_array_iter_from_dict(prop_dictionary_t, const char *);

/*
 * Lists information about all packages found in a dictionary, by
 * using a triplet: pkgname, version and short_desc.
 *
 * Arguments:
 * 	- prop_dictionary_t: dictionary where to search on.
 * 	- const char *: the key associated with the dictionary.
 */
void
xbps_list_pkgs_in_dict(prop_dictionary_t, const char *);

/*
 * Lists all string values in an array object in a dictionary.
 *
 * Arguments:
 * 	- prop_dictionary_t: dictionary that has the array.
 * 	- const char *: key of the array.
 */
void
xbps_list_strings_in_array(prop_dictionary_t, const char *);

/*
 * Registers a repository specified by an URI into the pool.
 *
 * Arguments:
 * 	- const char *: URI to register.
 *
 * Returns true on success, false on failure.
 */
bool
xbps_register_repository(const char *);

#endif /* !_XBPS_PLIST_UTILS_H_ */
