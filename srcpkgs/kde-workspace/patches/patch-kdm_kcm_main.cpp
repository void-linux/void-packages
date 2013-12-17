$NetBSD: patch-kdm_kcm_main.cpp,v 1.1 2012/03/19 19:44:03 markd Exp $

Allow $PKG_SYSCONFDIR/kdm/kdmrc to override the one under $PREFIX

--- kdm/kcm/main.cpp.orig	2010-05-27 17:23:09.000000000 +0000
+++ kdm/kcm/main.cpp
@@ -281,8 +281,12 @@ KConfig *KDModule::createTempConfig()
     pTempConfigFile->open();
     QString tempConfigName = pTempConfigFile->fileName();
 
+    QFile confFile (QString::fromLatin1( "@PKG_SYSCONFDIR@" "/kdm/kdmrc" ));
+    if ( !confFile.exists() )
+	confFile.setFileName (QString::fromLatin1( KDE_CONFDIR "/kdm/kdmrc" ));
+
     KConfig *pSystemKDMConfig = new KConfig(
-        QString::fromLatin1(KDE_CONFDIR "/kdm/kdmrc"), KConfig::SimpleConfig);
+        confFile.fileName(), KConfig::SimpleConfig);
 
     KConfig *pTempConfig = pSystemKDMConfig->copyTo(tempConfigName);
     pTempConfig->sync();
