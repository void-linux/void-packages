#!/bin/sh
# vlcj uses default NativeDiscovery; jna.library.path points it to system libvlc.
# VLC_PLUGIN_PATH tells libvlccore where to find its plugins from system vlc package.

export _JAVA_AWT_WM_NONREPARENTING=1
export VLC_PLUGIN_PATH=/usr/lib/vlc/plugins
export _JAVA_OPTIONS="-Djna.library.path=/usr/lib -Dawt.useSystemAAFontSettings=on -Dsun.java2d.xrender=true"

if [ -n "${SIMPLEX_SCALE}" ]; then
    export _JAVA_OPTIONS="${_JAVA_OPTIONS} -Dsun.java2d.uiScale=${SIMPLEX_SCALE}"
fi

if [ "${SIMPLEX_RENDER_API}" = "SOFTWARE" ]; then
    export SKIKO_RENDER_API=SOFTWARE
fi

exec /usr/lib/simplex-chat/simplex/bin/simplex "$@"
