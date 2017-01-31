$NetBSD: patch-thirdparty_mujs_jsdate.c,v 1.1 2017/01/30 14:06:05 leot Exp $

Backport a fix from upstream for CVE-2017-5628:

Fix 697496: Check NAN before accessing array in MakeDay().

--- thirdparty/mujs/jsdate.c.orig
+++ thirdparty/mujs/jsdate.c
@@ -207,12 +207,17 @@ static double MakeDay(double y, double m, double date)
 	};
 
 	double yd, md;
+	int im;
 
 	y += floor(m / 12);
 	m = pmod(m, 12);
 
+	im = (int)m;
+	if (im < 0 || im >= 12)
+		return NAN;
+
 	yd = floor(TimeFromYear(y) / msPerDay);
-	md = firstDayOfMonth[InLeapYear(y)][(int)m];
+	md = firstDayOfMonth[InLeapYear(y)][im];
 
 	return yd + md + date - 1;
 }
