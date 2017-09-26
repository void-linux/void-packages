--- WWW/Library/Implementation/HTTP.c.orig	2017-02-09 21:20:27 UTC
+++ WWW/Library/Implementation/HTTP.c
@@ -721,7 +722,7 @@ static int HTLoadHTTP(const char *arg,
 #elif SSLEAY_VERSION_NUMBER >= 0x0900
 #ifndef USE_NSS_COMPAT_INCL
 	if (!try_tls) {
-	    handle->options |= SSL_OP_NO_TLSv1;
+	    SSL_set_options(handle, SSL_OP_NO_TLSv1);
 #if OPENSSL_VERSION_NUMBER >= 0x0090806fL && !defined(OPENSSL_NO_TLSEXT)
 	} else {
 	    int ret = (int) SSL_set_tlsext_host_name(handle, ssl_host);
