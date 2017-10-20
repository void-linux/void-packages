* gsmartcontrol must be run with high privileges. So its desktop menu
  requires a running polkit authentication agent. GNOME or KDE DE
  provide it.  Otherwise, install lxpolkit that is a lightweight
  polkit auth agent.

* action "options > update Drive Database" does not work since
  smartmontools package does not provide this feature.
