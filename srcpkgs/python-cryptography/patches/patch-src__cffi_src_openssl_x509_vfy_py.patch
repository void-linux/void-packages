$OpenBSD: patch-src__cffi_src_openssl_x509_vfy_py,v 1.7 2018/02/22 18:49:16 sthen Exp $

Index: src/_cffi_src/openssl/x509_vfy.py
--- src/_cffi_src/openssl/x509_vfy.py.orig
+++ src/_cffi_src/openssl/x509_vfy.py
@@ -204,7 +204,7 @@ int sk_X509_OBJECT_num(Cryptography_STACK_OF_X509_OBJE
 X509_OBJECT *sk_X509_OBJECT_value(Cryptography_STACK_OF_X509_OBJECT *, int);
 X509_VERIFY_PARAM *X509_STORE_get0_param(X509_STORE *);
 Cryptography_STACK_OF_X509_OBJECT *X509_STORE_get0_objects(X509_STORE *);
-X509 *X509_OBJECT_get0_X509(X509_OBJECT *);
+X509 *X509_OBJECT_get0_X509(const X509_OBJECT *);
 int X509_OBJECT_get_type(const X509_OBJECT *);
 
 /* added in 1.1.0 */
@@ -220,14 +220,11 @@ static const long Cryptography_HAS_102_VERIFICATION_ER
 static const long Cryptography_HAS_102_VERIFICATION_PARAMS = 1;
 #else
 static const long Cryptography_HAS_102_VERIFICATION_ERROR_CODES = 0;
+#if LIBRESSL_VERSION_NUMBER >= 0x2070000fL
+static const long Cryptography_HAS_102_VERIFICATION_PARAMS = 1;
+#else
 static const long Cryptography_HAS_102_VERIFICATION_PARAMS = 0;
 
-static const long X509_V_ERR_SUITE_B_INVALID_VERSION = 0;
-static const long X509_V_ERR_SUITE_B_INVALID_ALGORITHM = 0;
-static const long X509_V_ERR_SUITE_B_INVALID_CURVE = 0;
-static const long X509_V_ERR_SUITE_B_INVALID_SIGNATURE_ALGORITHM = 0;
-static const long X509_V_ERR_SUITE_B_LOS_NOT_ALLOWED = 0;
-static const long X509_V_ERR_SUITE_B_CANNOT_SIGN_P_384_WITH_P_256 = 0;
 /* These 3 defines are unavailable in LibreSSL 2.5.x, but may be added
    in the future... */
 #ifndef X509_V_ERR_HOSTNAME_MISMATCH
@@ -240,12 +237,6 @@ static const long X509_V_ERR_EMAIL_MISMATCH = 0;
 static const long X509_V_ERR_IP_ADDRESS_MISMATCH = 0;
 #endif
 
-/* X509_V_FLAG_TRUSTED_FIRST is also new in 1.0.2+, but it is added separately
-   below because it shows up in some earlier 3rd party OpenSSL packages. */
-static const long X509_V_FLAG_SUITEB_128_LOS_ONLY = 0;
-static const long X509_V_FLAG_SUITEB_192_LOS = 0;
-static const long X509_V_FLAG_SUITEB_128_LOS = 0;
-
 int (*X509_VERIFY_PARAM_set1_host)(X509_VERIFY_PARAM *, const char *,
                                    size_t) = NULL;
 int (*X509_VERIFY_PARAM_set1_email)(X509_VERIFY_PARAM *, const char *,
@@ -257,6 +248,19 @@ void (*X509_VERIFY_PARAM_set_hostflags)(X509_VERIFY_PA
                                         unsigned int) = NULL;
 #endif
 
+static const long X509_V_ERR_SUITE_B_INVALID_VERSION = 0;
+static const long X509_V_ERR_SUITE_B_INVALID_ALGORITHM = 0;
+static const long X509_V_ERR_SUITE_B_INVALID_CURVE = 0;
+static const long X509_V_ERR_SUITE_B_INVALID_SIGNATURE_ALGORITHM = 0;
+static const long X509_V_ERR_SUITE_B_LOS_NOT_ALLOWED = 0;
+static const long X509_V_ERR_SUITE_B_CANNOT_SIGN_P_384_WITH_P_256 = 0;
+/* X509_V_FLAG_TRUSTED_FIRST is also new in 1.0.2+, but it is added separately
+   below because it shows up in some earlier 3rd party OpenSSL packages. */
+static const long X509_V_FLAG_SUITEB_128_LOS_ONLY = 0;
+static const long X509_V_FLAG_SUITEB_192_LOS = 0;
+static const long X509_V_FLAG_SUITEB_128_LOS = 0;
+#endif
+
 /* OpenSSL 1.0.2+ or Solaris's backport */
 #ifdef X509_V_FLAG_PARTIAL_CHAIN
 static const long Cryptography_HAS_X509_V_FLAG_PARTIAL_CHAIN = 1;
@@ -292,7 +296,7 @@ X509 *X509_STORE_CTX_get0_cert(X509_STORE_CTX *ctx)
     return ctx->cert;
 }
 
-X509 *X509_OBJECT_get0_X509(X509_OBJECT *x) {
+X509 *X509_OBJECT_get0_X509(const X509_OBJECT *x) {
     return x->data.x509;
 }
 #endif
