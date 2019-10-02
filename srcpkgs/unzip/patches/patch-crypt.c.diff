$NetBSD: patch-crypt.c,v 1.1 2015/11/11 12:47:27 wiz Exp $

Bug fix for heap overflow, from Debian.
CVE-2015-7696

--- crypt.c.orig	2007-01-05 15:47:36.000000000 +0000
+++ crypt.c
@@ -465,7 +465,17 @@ int decrypt(__G__ passwrd)
     GLOBAL(pInfo->encrypted) = FALSE;
     defer_leftover_input(__G);
     for (n = 0; n < RAND_HEAD_LEN; n++) {
-        b = NEXTBYTE;
+        /* 2012-11-23 SMS.  (OUSPG report.)
+         * Quit early if compressed size < HEAD_LEN.  The resulting
+         * error message ("unable to get password") could be improved,
+         * but it's better than trying to read nonexistent data, and
+         * then continuing with a negative G.csize.  (See
+         * fileio.c:readbyte()).
+         */
+        if ((b = NEXTBYTE) == (ush)EOF)
+        {
+            return PK_ERR;
+        }
         h[n] = (uch)b;
         Trace((stdout, " (%02x)", h[n]));
     }
