Since the 0.4 release, river no longer provides a window manager, riverctl
or rivertile. You need a separate window manager that implements river's
window management protocol.

To keep the previous self-contained river 0.3 setup, install the
river-classic package instead, it replaces river:

  xbps-install -S river-classic

More info: https://isaacfreund.com/blog/river-window-management/
River WM list: https://codeberg.org/river/wiki/src/branch/main/pages/wm-list.md
