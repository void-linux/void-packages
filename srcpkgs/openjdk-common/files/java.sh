#!/bin/sh
# allows scripts that assume java exists on PATH to work
# and helps users use java without logging out/in for the profile script
die() {
	echo "java: $@" >&2
	exit 1
}
. /etc/profile.d/jdk.sh
[ -d "$JAVA_HOME" ] || die "/usr/lib/jvm/default-jre not found. Check xbps-alternatives -lg java"
[ -x "$JAVA_HOME"/bin/java ] || die "$JAVA_HOME/bin/java does not exist or is not executable"
exec "$JAVA_HOME"/bin/java "$@"
