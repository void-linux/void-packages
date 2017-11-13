* gsmartcontrol needs elevated privileges, so its desktop menu entry requires
  a running polkit authentication agent. Almost all desktop shell environments
  provide it. You can also use lxpolkit (from lxsession) that is a lightweighti
  polkit auth agent.

* action "options > update Drive Database" does not work since
  smartmontools package does not provide this feature.
