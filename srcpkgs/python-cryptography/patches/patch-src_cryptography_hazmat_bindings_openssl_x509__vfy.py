--- src/cryptography/hazmat/bindings/openssl/x509_vfy.py.orig	2015-01-16 13:26:59 UTC
+++ src/cryptography/hazmat/bindings/openssl/x509_vfy.py
@@ -191,7 +191,7 @@ int X509_VERIFY_PARAM_set1_ip_asc(X509_V
 
 CUSTOMIZATIONS = """
 /* OpenSSL 1.0.2+ verification error codes */
-#if OPENSSL_VERSION_NUMBER >= 0x10002000L
+#if X509_V_ERR_EMAIL_MISMATCH
 static const long Cryptography_HAS_102_VERIFICATION_ERROR_CODES = 1;
 #else
 static const long Cryptography_HAS_102_VERIFICATION_ERROR_CODES = 0;
@@ -207,7 +207,7 @@ static const long X509_V_ERR_IP_ADDRESS_
 #endif
 
 /* OpenSSL 1.0.2+ verification parameters */
-#if OPENSSL_VERSION_NUMBER >= 0x10002000L
+#if X509_V_FLAG_PARTIAL_CHAIN
 static const long Cryptography_HAS_102_VERIFICATION_PARAMS = 1;
 #else
 static const long Cryptography_HAS_102_VERIFICATION_PARAMS = 0;
