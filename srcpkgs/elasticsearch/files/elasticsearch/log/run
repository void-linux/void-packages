#!/bin/sh
# Author: TJ Vanderpoel
# Licence: MIT
# This is a generic 'run' script meant to be linked in a log/ directory
# of a runit, daemontools, s6, or similar service.
# It requires svlogd available in the path.

# If the file './conf' exists, it can modify the behavior
# of the svlogd in these ways:

# USERGROUP=user:group (default rsvlog:adm)
# SV_LOGDIR=/path/to/log (default `basename $(dirname $PWD)`)
# CURRENT_LOG_FILE=filename.log (default 'current')

set -e
if [ $0 != "./run" ];then
  echo "This script meant to be linked as ./run in a service/log directory only!"
  exit 1
fi
curdir=$(basename $(pwd))
if [ "$curdir" != "log" ];then
  echo "This script meant to be run from a service/log directory only!"
  exit 1
fi
if [ -f ./conf ];then
  . ./conf
fi
if [ "x$SV_LOGDIR" != "x" ];then
  logdir=$SV_LOGDIR
fi
if [ -w /var/log ];then
  user_group=${USERGROUP:-rsvlog:adm}
  if [ "x$logdir" = "x" ];then
    logdir=$(basename $(dirname $(pwd)))
  fi
  [ -d "/var/log/$logdir" ] || mkdir -p "/var/log/$logdir"
  [ -L ./main ] || [ -d ./main ] || ln -s "/var/log/$logdir" ./main
  [ -L ./current ] || ln -s main/current
  if [ "x$CURRENT_LOG_FILE" != "x" ];then
    [ -L "/var/log/$logdir/$CURRENT_LOG_FILE" ] || ln -s current "/var/log/$logdir/$CURRENT_LOG_FILE"
  fi
  usergroup=$(stat -c "%U:%G" "/var/log/$logdir")
  if [ "$usergroup" != "$user_group" ];then
    chown -R $user_group "/var/log/$logdir"
  fi
  echo Logging as $user_group to /var/log/$logdir
  exec chpst -u $user_group svlogd -t ./main
else
  echo Logging in $PWD
  if [ "x$CURRENT_LOG_FILE" != "x" ];then
    [ -L "$CURRENT_LOG_FILE" ] || ln -s current "$CURRENT_LOG_FILE"
  fi
  exec svlogd -t ./
fi

