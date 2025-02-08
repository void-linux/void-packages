PWRFAILDIR="$( awk '$1 == "PWRFAILDIR" {print $2; exit}' /etc/apcupsd/apcupsd.conf )"
PWRFAILDIR="${PWRFAILDIR:-/etc/apcupsd}"

if [ -f "${PWRFAILDIR}/powerfail" ]; then
   msg "Powering off the UPS with APCUPSD..."
   /etc/apcupsd/apccontrol killpower
fi
