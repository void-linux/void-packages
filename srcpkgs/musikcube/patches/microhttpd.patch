Although musikcube thinks that MHD (microhttpd) version 0.9.70
defines MHD_Result, the headers installed by our version 0.9.70
(see PR 247180) don't define that type. So bump the version
check here trivially, to keep using int.
 
--- src/plugins/server/HttpServer.h.orig	2020-07-18 17:58:19 UTC
+++ src/plugins/server/HttpServer.h
@@ -43,7 +43,7 @@ extern "C" {
 #include <mutex>
 #include <vector>
 
-#if MHD_VERSION < 0x00097000
+#if MHD_VERSION < 0x00097001
 #define MHD_Result int
 #endif
 
