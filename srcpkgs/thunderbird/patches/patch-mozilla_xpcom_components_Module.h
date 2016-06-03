$NetBSD: patch-mozilla_xpcom_components_Module.h,v 1.2 2016/04/17 18:33:50 ryoon Exp $

--- mozilla/xpcom/components/Module.h.orig	2016-04-07 21:33:35.000000000 +0000
+++ mozilla/xpcom/components/Module.h
@@ -125,7 +125,7 @@ struct Module
 #    define NSMODULE_SECTION __declspec(allocate(".kPStaticModules$M"), dllexport)
 #  elif defined(__GNUC__)
 #    if defined(__ELF__)
-#      define NSMODULE_SECTION __attribute__((section(".kPStaticModules"), visibility("protected")))
+#      define NSMODULE_SECTION __attribute__((section(".kPStaticModules"), visibility("default")))
 #    elif defined(__MACH__)
 #      define NSMODULE_SECTION __attribute__((section("__DATA, .kPStaticModules"), visibility("default")))
 #    elif defined (_WIN32)
