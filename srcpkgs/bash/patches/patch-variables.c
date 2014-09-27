$NetBSD: patch-variables.c,v 1.1 2014/09/25 20:28:32 christos Exp $

Only read functions from environment if flag is set.

--- variables.c.christos	2014-09-25 16:09:41.000000000 -0400
+++ variables.c	2014-09-25 16:12:10.000000000 -0400
@@ -105,6 +105,7 @@
 extern int assigning_in_environment;
 extern int executing_builtin;
 extern int funcnest_max;
+extern int import_functions;
 
 #if defined (READLINE)
 extern int no_line_editing;
@@ -349,7 +350,7 @@
 
       /* If exported function, define it now.  Don't import functions from
 	 the environment in privileged mode. */
-      if (privmode == 0 && read_but_dont_execute == 0 && STREQN ("() {", string, 4))
+      if (import_functions && privmode == 0 && read_but_dont_execute == 0 && STREQN ("() {", string, 4))
 	{
 	  string_length = strlen (string);
 	  temp_string = (char *)xmalloc (3 + string_length + char_index);
