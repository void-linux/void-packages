#!/bin/sh
exec "$JAVA_HOME/bin/java" -cp "/usr/share/java/languagetool/languagetool-server.jar" "org.languagetool.server.HTTPServer" "$@"