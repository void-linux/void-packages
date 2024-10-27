#!/bin/sh
# from http://thedjbway.b0llix.net/clocksd/index.html
#
# clock_adjust.sh
# periodically get timing mark for clockspeed service

# initialize WAIT, WAIT_MAX:
WAIT=541
WAIT_MAX=2617923

# loop indefinitely
while :
do
    # obtain timing mark for calibrating clockspeed adjust:
    clockctl mark
    # log current "attoseconds":
    clockctl atto
    echo "==="
    echo "Waiting ${WAIT} seconds until next adjustment..."
    sleep ${WAIT}
    # increment $WAIT:
    WAIT=`expr ${WAIT} + ${WAIT} + ${WAIT}`
    if [ ${WAIT} -gt ${WAIT_MAX} ] ; then
        WAIT=${WAIT_MAX}
    fi
done
