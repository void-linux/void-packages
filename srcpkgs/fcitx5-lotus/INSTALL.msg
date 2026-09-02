This package installs the service differently from upstream.
DO NOT follow upstream's runit service activation method. Run instead:
  cp -r /usr/share/examples/sv/fcitx5-lotus /etc/sv/fcitx5-lotus.$(whoami)
  ln -s /etc/sv/fcitx5-lotus.$(whoami) /var/service/fcitx5-lotus.$(whoami)
