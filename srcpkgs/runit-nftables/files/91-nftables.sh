if [ -e /etc/nftables.conf ]; then
  nft -f /etc/nftables.conf
fi
