To use noctalia-greeter, set the greeter command in /etc/greetd/config.toml:

  [default_session]
  command = "/usr/bin/noctalia-greeter-session"
  user = "_greeter"

Then initialize the greeter state as root:

  # GREETER_USER=_greeter noctalia-greeter-apply-appearance --setup-system
