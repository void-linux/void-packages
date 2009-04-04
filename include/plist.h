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

#ifndef _XBPS_PLIST_H_
#define _XBPS_PLIST_H_

/* From lib/plist.c */
bool xbps_add_obj_to_dict(prop_dictionary_t, prop_object_t, const char *);
bool xbps_add_obj_to_array(prop_array_t, prop_object_t);

/*
 * Executes a function callback to process all objects that are
 * found in array with specified key inside of a dictionary.
 *
 * Arguments:
 * 	- prop_dictionary_t: dictionary to search on.
 *	- const char *: key of the array.
 *	- func(prop_object_t, void *, bool *): callback associated.
 *	- void *: argument for the callback.
 *
 * Returns true on success, false otherwise and the loop is terminated.
 */
int
xbps_callback_array_iter_in_dict(prop_dictionary_t, const char *,
				 int (*fn)(prop_object_t, void *, bool *),
				 void *);
int
xbps_callback_array_iter_in_repolist(int (*fn)(prop_object_t, void *, bool *),
				     void *);
/*
 * Finds a package's dictionary into the main dictionary.
 *
 * Arguments:
 * 	- prop_dictionary_t: main dictionary to search the object.
 * 	- const char *: string of package name.
 *
 * Returns the package's dictionary object, otherwise NULL.
 */
prop_dictionary_t
xbps_find_pkg_in_dict(prop_dictionary_t, const char *, const char *);

prop_dictionary_t
xbps_find_pkg_from_plist(const char *, const char *);

prop_dictionary_t
xbps_find_pkg_installed_from_plist(const char *);

/*
 * Finds a string object in an array.
 *
 * Arguments:
 * 	- prop_array_t: array to search for the string.
 * 	- const char *: string value of the object to be found.
 *
 * Returns true on success, false otherwise.
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
 * Remove package's dictionary from the "packages" array in
 * the specified plist file.
 *
 * Arguments:
 * 	- 1st const char *: package name.
 * 	- 2nd const char *: full path to plist file.
 *
 * Returns true on success, or false and an appropiate errno value otherwise.
 */
bool
xbps_remove_pkg_dict_from_file(const char *, const char *);

bool
xbps_remove_pkg_from_dict(prop_dictionary_t, const char *, const char *);

int
xbps_remove_string_from_array(prop_array_t, const char *);

#endif /* !_XBPS_PLIST_H_ */
