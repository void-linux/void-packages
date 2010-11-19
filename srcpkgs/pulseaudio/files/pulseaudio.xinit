#!/bin/sh

case "$SESSION" in
  GNOME|KDE*|xfce4) # PulseAudio is started via XDG Autostart
  ;;
  *) /usr/bin/start-pulseaudio-x11 ;;
esac
