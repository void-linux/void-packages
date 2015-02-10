$NetBSD: patch-extract.c,v 1.1 2014/12/25 16:48:33 wiz Exp $

Fixes for
* https://bugzilla.redhat.com/show_bug.cgi?id=CVE-2014-8139
* https://bugzilla.redhat.com/show_bug.cgi?id=CVE-2014-8140
* http://sf.net/projects/mancha/files/sec/unzip-6.0_overflow2.diff via
  http://seclists.org/oss-sec/2014/q4/1131 and
  http://seclists.org/oss-sec/2014/q4/507

--- extract.c.orig	2009-03-14 01:32:52.000000000 +0000
+++ extract.c
@@ -1,5 +1,5 @@
 /*
-  Copyright (c) 1990-2009 Info-ZIP.  All rights reserved.
+  Copyright (c) 1990-2014 Info-ZIP.  All rights reserved.
 
   See the accompanying file LICENSE, version 2009-Jan-02 or later
   (the contents of which are also included in unzip.h) for terms of use.
@@ -298,6 +298,8 @@ char ZCONST Far TruncNTSD[] =
 #ifndef SFX
    static ZCONST char Far InconsistEFlength[] = "bad extra-field entry:\n \
      EF block length (%u bytes) exceeds remaining EF data (%u bytes)\n";
+   static ZCONST char Far TooSmallEFlength[] = "bad extra-field entry:\n \
+     EF block length (%u bytes) invalid (< %d)\n";
    static ZCONST char Far InvalidComprDataEAs[] =
      " invalid compressed data for EAs\n";
 #  if (defined(WIN32) && defined(NTSD_EAS))
@@ -2023,7 +2025,8 @@ static int TestExtraField(__G__ ef, ef_l
         ebID = makeword(ef);
         ebLen = (unsigned)makeword(ef+EB_LEN);
 
-        if (ebLen > (ef_len - EB_HEADSIZE)) {
+        if (ebLen > (ef_len - EB_HEADSIZE))
+        {
            /* Discovered some extra field inconsistency! */
             if (uO.qflag)
                 Info(slide, 1, ((char *)slide, "%-22s ",
@@ -2032,6 +2035,16 @@ static int TestExtraField(__G__ ef, ef_l
               ebLen, (ef_len - EB_HEADSIZE)));
             return PK_ERR;
         }
+        else if (ebLen < EB_HEADSIZE)
+        {
+            /* Extra block length smaller than header length. */
+            if (uO.qflag)
+                Info(slide, 1, ((char *)slide, "%-22s ",
+                  FnFilter1(G.filename)));
+            Info(slide, 1, ((char *)slide, LoadFarString(TooSmallEFlength),
+              ebLen, EB_HEADSIZE));
+            return PK_ERR;
+        }
 
         switch (ebID) {
             case EF_OS2:
@@ -2217,14 +2230,28 @@ static int test_compr_eb(__G__ eb, eb_si
     ulg eb_ucsize;
     uch *eb_ucptr;
     int r;
+    ush method;
 
     if (compr_offset < 4)                /* field is not compressed: */
         return PK_OK;                    /* do nothing and signal OK */
 
+    /* Return no/bad-data error status if any problem is found:
+     *    1. eb_size is too small to hold the uncompressed size
+     *       (eb_ucsize).  (Else extract eb_ucsize.)
+     *    2. eb_ucsize is zero (invalid).  2014-12-04 SMS.
+     *    3. eb_ucsize is positive, but eb_size is too small to hold
+     *       the compressed data header.
+     */
     if ((eb_size < (EB_UCSIZE_P + 4)) ||
-        ((eb_ucsize = makelong(eb+(EB_HEADSIZE+EB_UCSIZE_P))) > 0L &&
-         eb_size <= (compr_offset + EB_CMPRHEADLEN)))
-        return IZ_EF_TRUNC;               /* no compressed data! */
+     ((eb_ucsize = makelong( eb+ (EB_HEADSIZE+ EB_UCSIZE_P))) == 0L) ||
+     ((eb_ucsize > 0L) && (eb_size <= (compr_offset + EB_CMPRHEADLEN))))
+        return IZ_EF_TRUNC;             /* no/bad compressed data! */
+
+    method = makeword(eb + (EB_HEADSIZE + compr_offset));
+    if ((method == STORED) && (eb_size - compr_offset != eb_ucsize))
+	return PK_ERR;			  /* compressed & uncompressed
+					   * should match in STORED
+					   * method */
 
     if (
 #ifdef INT_16BIT
