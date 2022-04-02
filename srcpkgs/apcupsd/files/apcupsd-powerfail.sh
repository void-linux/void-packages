PWRFAILDIR=$( grep -e ^PWRFAILDIR /etc/apcupsd/apcupsd.conf | cut -d ' ' -f 2 )
PWRFAILDIR=${PWRFAILDIR:=/etc/apcupsd}

if [ -f "${PWRFAILDIR}/powerfail" ]; then
   echo
   echo "APCUPSD will now power off the UPS"
   echo
   /etc/apcupsd/apccontrol killpower
fi
