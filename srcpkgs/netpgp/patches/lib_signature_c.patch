$NetBSD: patch-src_lib_signature.c,v 1.1 2018/03/15 20:21:52 khorben Exp $

Output signatures to the standard output for "-".

--- src/lib/signature.c.orig	2012-03-05 02:20:18.000000000 +0000
+++ src/lib/signature.c
@@ -903,7 +903,11 @@ open_output_file(pgp_output_t **output,
 
 	/* setup output file */
 	if (outname) {
-		fd = pgp_setup_file_write(output, outname, overwrite);
+		if (strcmp(outname, "-") == 0) {
+			fd = pgp_setup_file_write(output, NULL, overwrite);
+		} else {
+			fd = pgp_setup_file_write(output, outname, overwrite);
+		}
 	} else {
 		unsigned        flen = (unsigned)(strlen(inname) + 4 + 1);
 		char           *f = NULL;
