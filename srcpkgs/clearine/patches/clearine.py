--- a/src/clearine.py
+++ b/src/clearine.py
@@ -107,15 +107,15 @@ def setcontent(self):
         def find_key(data, section, key, default):
             helper = Helper()
             try:
-                if data is "arr":
+                if data=="arr":
                     return dotcat.get(section, key).split(",")
-                if data is "str":
+                if data=="str":
                     return dotcat.get(section, key, raw=True)
-                if data is "int":
+                if data=="int":
                     return dotcat.getint(section, key)
-                if data is "flo":
+                if data=="flo":
                     return dotcat.getfloat(section, key)
-                if data is "clr":
+                if data=="clr":
                     data = dotcat.get(section, key, raw=True)
                     if data.startswith("#") or data.startswith("rgba("):
                         return data
