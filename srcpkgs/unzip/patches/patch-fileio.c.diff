$NetBSD: patch-fileio.c,v 1.1 2014/12/25 16:48:33 wiz Exp $

https://bugzilla.redhat.com/show_bug.cgi?id=CVE-2014-8141

--- fileio.c.orig	2009-04-20 00:03:44.000000000 +0000
+++ fileio.c
@@ -176,6 +176,8 @@ static ZCONST char Far FilenameTooLongTr
 #endif
 static ZCONST char Far ExtraFieldTooLong[] =
   "warning:  extra field too long (%d).  Ignoring...\n";
+static ZCONST char Far ExtraFieldCorrupt[] =
+  "warning:  extra field (type: 0x%04x) corrupt.  Continuing...\n";
 
 #ifdef WINDLL
    static ZCONST char Far DiskFullQuery[] =
@@ -2295,7 +2297,12 @@ int do_string(__G__ length, option)   /*
             if (readbuf(__G__ (char *)G.extra_field, length) == 0)
                 return PK_EOF;
             /* Looks like here is where extra fields are read */
-            getZip64Data(__G__ G.extra_field, length);
+            if (getZip64Data(__G__ G.extra_field, length) != PK_COOL)
+            {
+                Info(slide, 0x401, ((char *)slide,
+                 LoadFarString( ExtraFieldCorrupt), EF_PKSZ64));
+                error = PK_WARN;
+            }
 #ifdef UNICODE_SUPPORT
             G.unipath_filename = NULL;
             if (G.UzO.U_flag < 2) {
