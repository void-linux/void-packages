$NetBSD: patch-share_base__image.c,v 1.1 2013/02/26 11:16:19 joerg Exp $

--- share/base_image.c.orig	2013-02-25 20:30:28.000000000 +0000
+++ share/base_image.c
@@ -94,7 +94,7 @@ static void *image_load_png(const char *
         default: longjmp(png_jmpbuf(readp), -1);
         }
 
-        if (!(bytep = png_malloc(readp, h * png_sizeof(png_bytep))))
+        if (!(bytep = png_malloc(readp, h * sizeof(*bytep))))
             longjmp(png_jmpbuf(readp), -1);
 
         /* Allocate the final pixel buffer and read pixels there. */
