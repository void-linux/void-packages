$NetBSD: patch-list.c,v 1.1 2015/01/06 14:12:45 wiz Exp $

Big-hammer fix for
http://seclists.org/oss-sec/2014/q4/497

--- list.c.orig	2009-02-08 17:11:34.000000000 +0000
+++ list.c
@@ -116,7 +116,7 @@ int list_files(__G)    /* return PK-type
     ulg acl_size, tot_aclsize=0L, tot_aclfiles=0L;
 #endif
     min_info info;
-    char methbuf[8];
+    char methbuf[80];
     static ZCONST char dtype[]="NXFS";  /* see zi_short() */
     static ZCONST char Far method[NUM_METHODS+1][8] =
         {"Stored", "Shrunk", "Reduce1", "Reduce2", "Reduce3", "Reduce4",
