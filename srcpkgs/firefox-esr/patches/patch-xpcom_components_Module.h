$NetBSD: patch-xpcom_components_Module.h,v 1.1 2016/02/06 22:13:22 ryoon Exp $

* Workaround for binutils/GNU ld 2.26 from NetBSD/amd64 7.99.26

--- xpcom/components/Module.h.orig	2016-01-23 23:23:51.000000000 +0000
+++ xpcom/components/Module.h
@@ -125,7 +125,7 @@ struct Module
 #    define NSMODULE_SECTION __declspec(allocate(".kPStaticModules$M"), dllexport)
 #  elif defined(__GNUC__)
 #    if defined(__ELF__)
-#      define NSMODULE_SECTION __attribute__((section(".kPStaticModules"), visibility("protected")))
+#      define NSMODULE_SECTION __attribute__((section(".kPStaticModules"), visibility("default")))
 #    elif defined(__MACH__)
 #      define NSMODULE_SECTION __attribute__((section("__DATA, .kPStaticModules"), visibility("default")))
 #    elif defined (_WIN32)
