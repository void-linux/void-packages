$NetBSD: patch-zipinfo.c,v 1.1 2017/02/04 23:25:59 wiz Exp $

Fix crash in zipinfo, CVE-2016-9844.
http://www.openwall.com/lists/oss-security/2016/12/05/19

--- zipinfo.c.orig	2009-02-08 17:04:30.000000000 +0000
+++ zipinfo.c
@@ -1921,7 +1921,18 @@ static int zi_short(__G)   /* return PK-
         ush  dnum=(ush)((G.crec.general_purpose_bit_flag>>1) & 3);
         methbuf[3] = dtype[dnum];
     } else if (methnum >= NUM_METHODS) {   /* unknown */
-        sprintf(&methbuf[1], "%03u", G.crec.compression_method);
+        /* 2016-12-05 SMS.
+         * https://launchpad.net/bugs/1643750
+         * Unexpectedly large compression methods overflow
+         * &methbuf[].  Use the old, three-digit decimal format
+         * for values which fit.  Otherwise, sacrifice the "u",
+         * and use four-digit hexadecimal.
+         */
+        if (G.crec.compression_method <= 999) {
+            sprintf( &methbuf[ 1], "%03u", G.crec.compression_method);
+        } else {
+            sprintf( &methbuf[ 0], "%04X", G.crec.compression_method);
+        }
     }
 
     for (k = 0;  k < 15;  ++k)
