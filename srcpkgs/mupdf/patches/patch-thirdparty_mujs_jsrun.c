$NetBSD: patch-thirdparty_mujs_jsrun.c,v 1.1 2017/01/30 14:06:05 leot Exp $

Backport a fix from upstream for CVE-2017-5627:

Fix 697497: Ensure array length is positive.

As a side effect when changing to using regular integers (and avoid the
nightmare of mixing signed and unsigned) we accidentally allowed negative
array lengths.

--- thirdparty/mujs/jsrun.c.orig
+++ thirdparty/mujs/jsrun.c
@@ -544,7 +544,7 @@ static void jsR_setproperty(js_State *J, js_Object *obj, const char *name)
 		if (!strcmp(name, "length")) {
 			double rawlen = jsV_tonumber(J, value);
 			int newlen = jsV_numbertointeger(rawlen);
-			if (newlen != rawlen)
+			if (newlen != rawlen || newlen < 0)
 				js_rangeerror(J, "array length");
 			jsV_resizearray(J, obj, newlen);
 			return;
