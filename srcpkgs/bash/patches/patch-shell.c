$NetBSD: patch-shell.c,v 1.1 2014/09/25 20:28:32 christos Exp $

Add flag to disable importing of function unless explicitly enabled

--- shell.c.christos	2014-01-14 08:04:32.000000000 -0500
+++ shell.c	2014-09-25 16:11:51.000000000 -0400
@@ -229,6 +229,7 @@
 #else
 int posixly_correct = 0;	/* Non-zero means posix.2 superset. */
 #endif
+int import_functions = 0;	/* Import functions from environment */
 
 /* Some long-winded argument names.  These are obviously new. */
 #define Int 1
@@ -248,6 +249,7 @@
   { "help", Int, &want_initial_help, (char **)0x0 },
   { "init-file", Charp, (int *)0x0, &bashrc_file },
   { "login", Int, &make_login_shell, (char **)0x0 },
+  { "import-functions", Int, &import_functions, (char **)0x0 },
   { "noediting", Int, &no_line_editing, (char **)0x0 },
   { "noprofile", Int, &no_profile, (char **)0x0 },
   { "norc", Int, &no_rc, (char **)0x0 },
