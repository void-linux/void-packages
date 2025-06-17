if [ -e /etc/iptables/iptables.rules ]; then
  iptables-restore /etc/iptables/iptables.rules
fi

if [ -e /etc/iptables/ip6tables.rules ]; then
  ip6tables-restore /etc/iptables/ip6tables.rules
fi
