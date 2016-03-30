$OpenBSD: patch-socket_c,v 1.9 2015/08/25 17:44:09 jca Exp $

Fixed upstream

  https://gitlab.com/fetchmail/fetchmail/commit/a2ae6f8d15d7caf815d7bdd13df833fd1b2af5cc

--- socket.c.orig	Fri Jul 17 22:01:09 2015
+++ socket.c	Fri Jul 17 22:19:47 2015
@@ -914,7 +914,12 @@ int SSLOpen(int sock, char *mycert, char *mykey, const
 			return -1;
 #endif
 		} else if(!strcasecmp("ssl3",myproto)) {
+#if HAVE_DECL_SSLV3_CLIENT_METHOD + 0 > 0
 			_ctx[sock] = SSL_CTX_new(SSLv3_client_method());
+#else
+			report(stderr, GT_("Your operating system does not support SSLv3.\n"));
+			return -1;
+#endif
 		} else if(!strcasecmp("tls1",myproto)) {
 			_ctx[sock] = SSL_CTX_new(TLSv1_client_method());
 		} else if (!strcasecmp("ssl23",myproto)) {
