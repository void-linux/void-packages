#!/bin/sh

case "$1" in
   pre)
       logger -t nvidia-sleep "Entering $2 mode (invoked by $SYSTEMD_SLEEP_ACTION)"
       /usr/bin/nvidia-sleep.sh "hibernate"
       ret=$?
       if [ $ret -ne 0 ]; then
               logger -t nvidia-sleep "Failed to enter $2 mode (exit code $ret)"
               exit $ret
       fi
       sleep 5
       logger -t nvidia-sleep "Entered $2 mode (invoked by $SYSTEMD_SLEEP_ACTION)"
       ;;
   post)
       logger -t nvidia-sleep "Exiting $2 mode (invoked by $SYSTEMD_SLEEP_ACTION)"
       /usr/bin/nvidia-sleep.sh "resume"
       ret=$?
       if [ $ret -ne 0 ]; then
               logger -t nvidia-sleep "Failed to exit $2 mode (exit code $ret)"
               exit $ret
       fi
       logger -t nvidia-sleep "Exited $2 mode (invoked by $SYSTEMD_SLEEP_ACTION)"
       ;;
esac
