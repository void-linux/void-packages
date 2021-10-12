#!/bin/sh
# Begin remove-expired-certs.sh
#
# Version 20120211

# Make sure the date is parsed correctly on all systems
mydate()
{
  local y=$( echo $1 | cut -d" " -f4 )
  local M=$( echo $1 | cut -d" " -f1 )
  local d=$( echo $1 | cut -d" " -f2 )
  local m

  [ -z "${d}" ] && d="0"
  [ "${d}" -lt 10 ] && d="0${d}"

  case $M in
    Jan) m="01";;
    Feb) m="02";;
    Mar) m="03";;
    Apr) m="04";;
    May) m="05";;
    Jun) m="06";;
    Jul) m="07";;
    Aug) m="08";;
    Sep) m="09";;
    Oct) m="10";;
    Nov) m="11";;
    Dec) m="12";;
  esac

  certdate="${y}${m}${d}"
}

DIR="$1"
[ -z "$DIR" ] && DIR=$(pwd)

today=$(date +%Y%m%d)

find ${DIR} -type f -a -iname "*.crt" -printf "%p\n" | while read cert; do
  notafter=$(/usr/bin/openssl x509 -enddate -in "${cert}" -noout)
  date=$( echo ${notafter} |  sed 's/^notAfter=//' )
  mydate "$date"

  if [ ${certdate} -lt ${today} ]; then
     echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
     echo "EXPIRED CERTIFICATE FOUND $certdate: \"$(basename ${cert})\""
     echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
     rm -f "${cert}"
  fi
done
