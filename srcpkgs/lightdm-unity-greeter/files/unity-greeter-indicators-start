#!/bin/sh

# Load each indicator in turn respecting unity-greeter's dconf setting #
#  This is necessary since starting indicators via dbus has been deprecated in favour of using 'upstart' init system services #
for indicator in $(gsettings get com.canonical.unity-greeter indicators | \
				sed "s/,/\\n/g; s/[]\[']//g" | grep com.canonical | \
					sed "s/com.canonical.//g; s/\./-/g"); do
	if [ -x /usr/lib/${indicator}/${indicator}-service ]; then
		exec /usr/lib/${indicator}/${indicator}-service &
	fi
done
