--- src/cryptography/hazmat/bindings/openssl/rand.py.orig	2015-01-16 13:26:59 UTC
+++ src/cryptography/hazmat/bindings/openssl/rand.py
@@ -16,9 +16,6 @@ void ERR_load_RAND_strings(void);
 void RAND_seed(const void *, int);
 void RAND_add(const void *, int, double);
 int RAND_status(void);
-int RAND_egd(const char *);
-int RAND_egd_bytes(const char *, int);
-int RAND_query_egd_bytes(const char *, unsigned char *, int);
 const char *RAND_file_name(char *, size_t);
 int RAND_load_file(const char *, long);
 int RAND_write_file(const char *);
