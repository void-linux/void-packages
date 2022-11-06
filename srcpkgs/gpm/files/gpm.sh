case $( /usr/bin/tty ) in
    /dev/tty[0-9]*) [ -n "$(pgrep gpm)" ] && /usr/bin/disable-paste ;;
esac
