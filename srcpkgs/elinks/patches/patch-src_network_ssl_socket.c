--- src/network/ssl/socket.c.orig	2017-02-08 12:49:43 UTC
+++ src/network/ssl/socket.c
@@ -67,7 +67,7 @@ static void
 ssl_set_no_tls(struct socket *socket)
 {
 #ifdef CONFIG_OPENSSL
-	((ssl_t *) socket->ssl)->options |= SSL_OP_NO_TLSv1;
+	SSL_set_options((ssl_t *) socket->ssl, SSL_OP_NO_TLSv1);
 #elif defined(CONFIG_GNUTLS)
 	{
 		/* GnuTLS does not support SSLv2 because it is "insecure".
