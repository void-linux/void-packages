*** IMPORTANT ***

You most likely need to export SBCL_HOME before running StumpWM.
See https://github.com/stumpwm/stumpwm/issues/760 for more info.
In most cases when using Bash it will suffice to execute:

export SBCL_HOME=/usr/lib/sbcl/

before running /usr/bin/stumpwm.

*** EVEN MORE IMPORTANT ***

Should you update SBCL you MUST also update StumpWM because of compiled
code compatibility. Updating SBCL without updating StumpWM will lead to
strange errors when you start StumpWM.
