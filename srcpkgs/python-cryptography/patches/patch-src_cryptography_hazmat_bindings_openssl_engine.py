--- src/cryptography/hazmat/bindings/openssl/engine.py.orig	2015-01-16 13:26:59 UTC
+++ src/cryptography/hazmat/bindings/openssl/engine.py
@@ -49,7 +49,6 @@ int ENGINE_init(ENGINE *);
 int ENGINE_finish(ENGINE *);
 void ENGINE_load_openssl(void);
 void ENGINE_load_dynamic(void);
-void ENGINE_load_cryptodev(void);
 void ENGINE_load_builtin_engines(void);
 void ENGINE_cleanup(void);
 ENGINE *ENGINE_get_default_RSA(void);
