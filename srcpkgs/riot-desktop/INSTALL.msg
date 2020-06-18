Since Riot 1.6, it uses Electron 8. This version of Electron has
dropped support for the older XEmbed system tray API. If you are using
a desktop or window manager that does not support StatusNotifierItems
(i3, awesome, stalonetray, etc), you should install and configure
snixembed:

   xbps-install -S snixembed

More instructions at: https://git.sr.ht/~steef/snixembed/

