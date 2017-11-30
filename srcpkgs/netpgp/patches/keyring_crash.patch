$NetBSD: patch-src_lib_keyring.c,v 1.1 2017/02/20 01:09:11 khorben Exp $

Do not crash when listing keys without a keyring

--- src/lib/keyring.c.orig	2017-02-20 01:03:25.000000000 +0000
+++ src/lib/keyring.c
@@ -993,9 +993,12 @@ pgp_keyring_list(pgp_io_t *io, const pgp
 {
 	pgp_key_t		*key;
 	unsigned		 n;
+	unsigned		 keyc = (keyring != NULL) ? keyring->keyc : 0;
 
-	(void) fprintf(io->res, "%u key%s\n", keyring->keyc,
-		(keyring->keyc == 1) ? "" : "s");
+	(void) fprintf(io->res, "%u key%s\n", keyc, (keyc == 1) ? "" : "s");
+	if (keyring == NULL) {
+		return 1;
+	}
 	for (n = 0, key = keyring->keys; n < keyring->keyc; ++n, ++key) {
 		if (pgp_is_key_secret(key)) {
 			pgp_print_keydata(io, keyring, key, "sec",
