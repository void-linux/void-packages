#!/bin/bash
#
# OMXPlayer wrapper script. Fixes some common issues.
#
# Author: Sergio Conde <skgsergio@gmail.com>
# License: GPLv2
#

OMXPLAYER_BIN="/usr/bin/omxplayer.bin"
OMXPLAYER_LIBS="/opt/vc/lib:/usr/lib/omxplayer"

refresh_regex='(|.* )(-r|--refresh)( .*|$)'
audio_regex='.*\.(mp3|wav|wma|cda|ogg|ogm|aac|ac3|flac)( .*|$)'

fbset_bin=`which fbset 2>/dev/null`
xset_bin=`which xset 2>/dev/null`
xrefresh_bin=`which xrefresh 2>/dev/null`

if [ -z $NOREFRESH ] || [ "$NOREFRESH" == "0" ]; then
    if [[ $@ =~ $refresh_regex ]] && [[ ! $@ =~ $audio_regex ]]; then
        check_failed=0

        if [ -z $fbset_bin ]; then
            echo "WARNING: You are going to run omxplayer with -r/--refresh and you don't have fbset installed, this can cause black screen when it finishes playing."
            check_failed=1
        fi

        if [ ! -z $DISPLAY ]; then
            if [ -z $xset_bin ] || [ -z $xrefresh_bin ]; then
                echo "WARNING: You are going to run omxplayer with -r/--refresh and you don't have xset installed, this can cause black screen when it finishes playing."
                check_failed=1
            fi
        fi

        if [ "$check_failed" == "1" ]; then
            read -sn 1 -p "Press any key to continue or Ctrl-C to quit."
            echo
        fi
    fi
fi

OMXPLAYER_DBUS_ADDR=`mktemp -t omxplayer-XXXXX`
OMXPLAYER_DBUS_PID=`mktemp -t omxplayer-XXXXX`

exec 5> $OMXPLAYER_DBUS_ADDR
exec 6> $OMXPLAYER_DBUS_PID

dbus-daemon --fork --print-address 5 --print-pid 6 --session

DBUS_SESSION_BUS_ADDRESS=`cat $OMXPLAYER_DBUS_ADDR`
DBUS_SESSION_BUS_PID=`cat $OMXPLAYER_DBUS_PID`

export DBUS_SESSION_BUS_ADDRESS
export DBUS_SESSION_BUS_PID

LD_LIBRARY_PATH="$OMXPLAYER_LIBS${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" $OMXPLAYER_BIN "$@"; true

if [ -n "$DBUS_SESSION_BUS_PID" ]; then
    kill -2 "$DBUS_SESSION_BUS_PID"
fi

rm -f $OMXPLAYER_DBUS_ADDR
rm -f $OMXPLAYER_DBUS_PID

if [ ! -z $NOREFRESH ] && [ "$NOREFRESH" == "1" ]; then
    exit 0
fi

if [[ $@ =~ $audio_regex ]]; then
    exit 0
fi

if [[ $@ =~ $refresh_regex ]]; then
    if [ ! -z $fbset_bin ]; then
        DEPTH2=`$fbset_bin | head -3 | tail -1 | cut -d " " -f 10`

        if [ "$DEPTH2" == "8" ]; then
            DEPTH1=16
        elif [ "$DEPTH2" == "16" ] || [ "$DEPTH2" == "32" ]; then
            DEPTH1=8
        else
            DEPTH1=8
            DEPTH2=16
        fi

        $fbset_bin -depth $DEPTH1 > /dev/null 2>&1
        $fbset_bin -depth $DEPTH2 > /dev/null 2>&1
    fi

    if [ ! -z $xset_bin ] && [ ! -z $xrefresh_bin ]; then
        if [ -z $DISPLAY ]; then
            DISPLAY=":0"
        fi

        $xset_bin -display $DISPLAY -q > /dev/null 2>&1
        if [ "$?" == "0" ]; then
            $xrefresh_bin -display $DISPLAY > /dev/null 2>&1
        fi
    fi
fi
