--- ./xmlIO.c.orig	2009-09-24 08:32:00.000000000 -0700
+++ ./xmlIO.c	2010-03-17 12:35:00.957293884 -0700
@@ -2518,6 +2518,9 @@
 #ifdef HAVE_ZLIB_H
 	if ((xmlInputCallbackTable[i].opencallback == xmlGzfileOpen) &&
 		(strcmp(URI, "-") != 0)) {
+#if defined(ZLIB_VERNUM) && ZLIB_VERNUM >= 0x1230
+	    ret->compressed = !gzdirect(context);
+#else
 	    if (((z_stream *)context)->avail_in > 4) {
 	        char *cptr, buff4[4];
 		cptr = (char *) ((z_stream *)context)->next_in;
@@ -2529,6 +2532,7 @@
 		    gzrewind(context);
 		}
 	    }
+#endif
 	}
 #endif
     }
