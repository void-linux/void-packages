
Logging that one reads from the log causes an infinite loop.

--- src/sshguard_logsuck.c.orig	2015-11-11 23:00:05.096089572 +0000
+++ src/sshguard_logsuck.c	2016-03-09 19:18:06.326044898 +0000
@@ -286,7 +286,6 @@
     }
     list_iterator_stop(& sources_list);
 
-    sshguard_log(LOG_INFO, "Refreshing sources showed %u changes.", numchanged);
     return 0;
 }
 

