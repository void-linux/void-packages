$NetBSD$

Fix vulnerability reported in SA56624. Patch taken from here:

http://hg.python.org/cpython/rev/87673659d8f7

--- Modules/socketmodule.c.orig	2013-11-10 07:36:41.000000000 +0000
+++ Modules/socketmodule.c	2014-02-09 08:41:25.000000000 +0000
@@ -2742,6 +2742,10 @@
     if (recvlen == 0) {
         /* If nbytes was not specified, use the buffer's length */
         recvlen = buflen;
+    } else if (recvlen > buflen) {
+        PyErr_SetString(PyExc_ValueError,
+                        "nbytes is greater than the length of the buffer");
+        goto error;
     }
 
     readlen = sock_recvfrom_guts(s, buf.buf, recvlen, flags, &addr);
