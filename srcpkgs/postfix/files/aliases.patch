--- etc/postfix/main.cf.orig	2010-12-13 20:18:22.000000000 +0100
+++ etc/postfix/main.cf	2010-12-13 20:18:24.000000000 +0100
@@ -382,6 +382,7 @@
 #alias_maps = hash:/etc/aliases
 #alias_maps = hash:/etc/aliases, nis:mail.aliases
 #alias_maps = netinfo:/aliases
+alias_maps = hash:/etc/postfix/aliases
 
 # The alias_database parameter specifies the alias database(s) that
 # are built with "newaliases" or "sendmail -bi".  This is a separate
@@ -392,6 +393,7 @@
 #alias_database = dbm:/etc/mail/aliases
 #alias_database = hash:/etc/aliases
 #alias_database = hash:/etc/aliases, hash:/opt/majordomo/aliases
+alias_database = $alias_maps
 
 # ADDRESS EXTENSIONS (e.g., user+foo)
 #
