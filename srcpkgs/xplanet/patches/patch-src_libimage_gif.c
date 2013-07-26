$NetBSD: patch-src_libimage_gif.c,v 1.1 2013/07/06 08:00:47 ryoon Exp $

* Fix build with giflib 5.0.

--- src/libimage/gif.c.orig	2006-03-25 22:50:51.000000000 +0000
+++ src/libimage/gif.c
@@ -21,8 +21,27 @@
 #include <stdio.h>
 #include <stdlib.h>
 
+#ifndef	TRUE
+#define	TRUE	1
+#endif
+#ifndef	FALSE
+#define	FALSE	0
+#endif
 #include <gif_lib.h>
 
+/* from util/qprintf.c of giflib 5.0.4 */
+int ErrorCode;
+void
+PrintGifError(int ErrorCode)
+{
+    char *Err = GifErrorString(ErrorCode);
+
+    if (Err != NULL)
+	fprintf(stderr, "GIF-LIB error: %s.\n", Err);
+    else
+	fprintf(stderr, "GIF-LIB undefined error %d.\n", ErrorCode);
+}
+
 /*
   A lot of this is based on the gif2rgb and rgb2gif codes in the libungif 
   distribution. 
@@ -42,11 +61,11 @@ read_gif(const char *filename, int *widt
     int color_index;
     unsigned char *ptr = NULL;
 
-    infile = DGifOpenFileName(filename);
+    infile = DGifOpenFileName(filename, &ErrorCode);
 
     if (infile == NULL)
     {
-        PrintGifError();
+        PrintGifError(ErrorCode);
         return(0);
     }
 
@@ -54,7 +73,7 @@ read_gif(const char *filename, int *widt
     {
         if (DGifGetRecordType(infile, &record_type) == GIF_ERROR) 
         {
-            PrintGifError();
+            PrintGifError(ErrorCode);
             return(0);
         }
 
@@ -63,7 +82,7 @@ read_gif(const char *filename, int *widt
         case IMAGE_DESC_RECORD_TYPE:
             if (DGifGetImageDesc(infile) == GIF_ERROR)
             {
-                PrintGifError();
+                PrintGifError(ErrorCode);
                 return(0);
             }
 
@@ -107,14 +126,14 @@ read_gif(const char *filename, int *widt
             GifByteType *ext;
             if (DGifGetExtension(infile, &ext_code, &ext) == GIF_ERROR) 
             {
-                PrintGifError();
+                PrintGifError(ErrorCode);
                 return(0);
             }
             while (ext != NULL) 
             {
                 if (DGifGetExtensionNext(infile, &ext) == GIF_ERROR) 
                 {
-                    PrintGifError();
+                    PrintGifError(ErrorCode);
                     return(0);
                 }
             }
@@ -178,7 +197,7 @@ write_gif(const char *filename, int widt
         return(0);
     }
 
-    colormap = MakeMapObject(colormap_size, NULL);
+    colormap = GifMakeMapObject(colormap_size, NULL);
 
     for (i = 0; i < width * height; i++)
     {
@@ -187,10 +206,10 @@ write_gif(const char *filename, int widt
         blue[i]  = (GifByteType) rgb[3*i+2];
     }
   
-    if (QuantizeBuffer(width, height, &colormap_size, red, green, blue,   
+    if (GifQuantizeBuffer(width, height, &colormap_size, red, green, blue,   
                        buffer, colormap->Colors) == GIF_ERROR)
     {
-        PrintGifError();
+        PrintGifError(ErrorCode);
         return(0);
     }
 
@@ -198,24 +217,24 @@ write_gif(const char *filename, int widt
     free(green);
     free(blue);
 
-    outfile = EGifOpenFileName((char *) filename, FALSE);
+    outfile = EGifOpenFileName((char *) filename, FALSE, &ErrorCode);
     if (outfile == NULL)
     {
-        PrintGifError();
+        PrintGifError(ErrorCode);
         return(0);
     }
 
     if (EGifPutScreenDesc(outfile, width, height, colormap_size, 0, colormap)
         == GIF_ERROR)
     {
-        PrintGifError();
+        PrintGifError(ErrorCode);
         return(0);
     }
 
     if (EGifPutImageDesc(outfile, 0, 0, width, height, FALSE, NULL)
         == GIF_ERROR)
     {
-        PrintGifError();
+        PrintGifError(ErrorCode);
         return(0);
     }
 
@@ -224,7 +243,7 @@ write_gif(const char *filename, int widt
     {
         if (EGifPutLine(outfile, ptr, width) == GIF_ERROR)
         {
-            PrintGifError();
+            PrintGifError(ErrorCode);
             return(0);
         }
         ptr += width;
@@ -233,7 +252,7 @@ write_gif(const char *filename, int widt
     EGifSpew(outfile);
 
     if (EGifCloseFile(outfile) == GIF_ERROR) 
-        PrintGifError();
+        PrintGifError(ErrorCode);
 
     free(buffer);
 
