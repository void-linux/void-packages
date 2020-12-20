#!/bin/bash

# revision 0.2


# select which profile types to use: "a2dp", "sco", or "all"
profiles="${BMIX_PROFILE:-all}"

# d-bus service name for bluealsa
servicename="${BMIX_BLUEALSA_SRV:-org.bluealsa}"

# experiment with higher latency if you experience underruns/overruns
latency="${BMIX_LATENCY:-50000}"

# location of dynamic alsa configuration file
conffile="${BMIX_ALSA_CONF:-/var/lib/bmix/bmix.conf}"

# dmix ipc will use 8 consecutive ipc key numbers starting with this value
ipc_key_start=${BMIX_IPC_KEY:-30000}

# to reserve some Loopback substreams for other applications, set the lowest
# substream to use here:
lowest_loop_substream=${BMIX_LOOPBACK:-0}

# name to use for default bluetooth pcm
default_pcm_name="${BMIX_DEFAULT_PCM_NAME:-bluetooth}"

# extra arguments to apply to alsaloop
alsaloop_args="${BMIX_ALSALOOP_ARGS:---sync=none}"


ALSALOOP="alsaloop $alsaloop_args"


awk_parse_dbus_message='
	/member=PCMAdded/   { added = 1; next; }
	/member=PCMRemoved/ { removed = 1; next; }
	/member=NameOwnerChanged/ { printf("ServiceStopped\n"); fflush(); next; }
	!/variant/ && /object path/ {
		match($0, /dev_([[:xdigit:]_]+)\/(a2dp|hfp|hsp)(.*)/, arr)
		if (RSTART > 0) {
			brackets = 0
			addr = arr[1]
			if (removed) {
				if (arr[2] ~ /hfp|hsp/)
					profile = "SCO"
				else if (arr[2] ~ a2dp)
					profile = "A2DP"
				else
					next
				if (arr[3] ~ /source/)
					printf("PCMRemoved %s %s %s\n", addr, profile, "source")
				else if (arr[3] ~ /sink/)
					printf("PCMRemoved %s %s %s\n", addr, profile, "sink")
				else
					next
				fflush()
				removed = 0
				next
			}
			profile = ""
			mode = ""
			format = ""
			channels = ""
			sampling = ""
			next
		}
	}
	/string "Transport"/ { t = 1; next; }
	/string "Mode/       { m = 1; next; }
	/string "Format"/    { f = 1; next; }
	/string "Channels"/  { c = 1; next; }
	/string "Sampling"/  { s = 1; next; }
	t && /A2DP/    { profile = "A2DP"; t = 0; next; }
	t && /HFP|HSP/ { profile = "SCO"; t = 0; next; }
	m && /string/ {
		sub(/^.*string /,"")
		gsub("\"","")
		mode = $0
		next
	}
	f && /uint16/ { format = $NF; f = 0; next; }
	c && /byte/   { channels = $NF; c = 0; next; }
	s && /uint32/ { sampling = $NF; s = 0; next; }
	m && /)/ { m = 0; next; }
	t && /)/ { t = 0; next; }
	f && /)/ { f = 0; next; }
	c && /)/ { c = 0; next; }
	s && /)/ { s = 0; next; }
	/\[/ { brackets++; next; }
	addr && /]/ && (--brackets == 0) {
		if (addr && profile && mode && format && channels && sampling) {
			if (added)
				printf("PCMAdded ")
			printf("%s %s %s %s %s %s\n", addr, profile, mode, format, channels, sampling)
			fflush()
			added = 0
		}
	}
'

declare -A formats
formats[264]=U8
formats[33296]=S16_LE
formats[33560]=S24_3LE
formats[33816]=S24_LE
formats[33824]=S32_LE
formats[8]=U8            # pre bluealsa v3.0.0
formats[32784]=S16_LE    # pre bluealsa v3.0.0
formats[32792]=S24_LE    # pre bluealsa v3.0.0

declare -A select_profile
select_profile[A2DP]=yes
select_profile[SCO]=yes

profiles=${profiles^^?}
if [[ "$profiles" = SCO ]] ; then
	select_profile[A2DP]=no
elif [[ "$profiles" = A2DP ]] ; then
	select_profile[SCO]=no
fi

declare -A pids
declare -A loops
declare -A name

declare default_devid=""

declare -i first_loop="$lowest_loop_substream"
declare -i num_loops=$(grep -c substream /proc/asound/Loopback/cable\#0)

get_loop_by_devid() {
	declare -n result=$1
	declare devid="$2"
	declare i
	result=""
	for i in "${!loops[@]}" ; do
		if [[ "$i" = "$devid" ]] ; then
			result=${loops[$i]}
			break
		fi
	done
	if [[ -z "$result" ]] ; then
		declare -i next_loop=$((first_loop + ${#loops[@]}))
		if [[ $next_loop -lt $num_loops ]] ; then
			loops["$devid"]=$next_loop
			result=$next_loop
		fi
	fi
}

launch_alsaloop() {
	# arg1 devid
	# arg2 loop
	# arg3 addr
	# arg4 profile
	# arg5 format
	# arg6 channels
	# arg7 sample rate
	declare devid="$1" loop=$2 addr="$3" profile="$4" format="$5" channels=$6 rate=$7 pid

	sleep 2
	$ALSALOOP -f "$format" -c "$channels" -r "$rate" -C hw:Loopback,1,$loop -P bluealsa_raw:SRV="$servicename",DEV="$addr",PROFILE="$profile",DELAY=0 -t "$latency" >/dev/null 2>&1 &
	pid=$!
	sleep 1
	if ! kill -0 $pid >/dev/null 2>&1; then
		echo "failed to start alsaloop for $addr ($profile)" >&2
		return 1
	fi
	pids["$devid"]=$pid
}

create_alsa_config() {
	# arg1 device id
	# arg2 device alias
	# arg3 profile
	# arg4 channels
	# arg5 rate
	declare devid="$1" dev_alias="$2" profile="$3"
	declare -i channels=$4 rate=$5
	declare -i ipc_key=$((ipc_key_start + loops[$devid]))
	declare loop

	cat >> "$conffile" <<-EOF
	pcm."${name[$devid]}".type empty
	pcm."${name[$devid]}".slave.pcm "bmix:IPC_KEY=${ipc_key},LOOP=${loops[$devid]},CHANNELS=${channels},RATE=${rate},PERIOD=$(($latency / 2))"
	pcm."${name[$devid]}".hint.show.@func refer
	pcm."${name[$devid]}".hint.show.name defaults.namehint.basic
	pcm."${name[$devid]}".hint.description "$dev_alias ($profile) Bluetooth Audio Playback"
	EOF
}

# get device alias from Bluez
get_alias() {
	# arg1 name of variable to store result
	# arg2 addr (underscored)
	declare -n result="$1"
	result=$(dbus-send --print-reply=literal --system --dest=org.bluez \
	    /org/bluez/hci0/dev_$2 \
	    org.freedesktop.DBus.Properties.Get string:"org.bluez.Device1" string:"Alias")
	result=${result#   variant       }
}

add_pcm() {
	# arg1 addr (underscored)
	# arg2 profile
	# arg3 format
	# arg4 channels
	# arg5 sample rate
	declare devid="$1,$2" profile="$2" format=${formats["$3"]} addr="${1//_/:}"
	declare -i channels=$4 rate=$5
	declare loop dev_alias

	get_alias dev_alias "$1"
	[[ -n "$dev_alias" ]] || return 1

	get_loop_by_devid loop $devid

	if [[ -z "$loop" ]] ; then
		echo "No free Loopback substreams" >&2
		return 1
	fi
	launch_alsaloop "$devid" "$loop" "$addr" "$profile" "$format" "$channels" "$rate" \
	  || return 1
	name["$devid"]="$dev_alias - $profile"
	create_alsa_config "$devid" "$dev_alias" "$profile" "$channels" "$rate"
}

remove_pcm() {
	#arg1 devid
	declare devid="$1"
	sed -i '/^pcm."'"${name["$devid"]}"'/d' "$conffile"
	kill "${pids["$devid"]}" 2>/dev/null
	unset pids["$devid"]
	unset name["$devid"]
}

# make sure default name is alias for pcm that is currently connected
update_default() {
	for devid in "${!name[@]}" ; do
		[[ "$devid" = "$default_devid" ]] && return
	done
	declare -a arr=("${!name[@]}")
	default_devid="${arr[0]}"
	sed -i -e '/^pcm."'"$default_pcm_name"'/d' "$conffile"	2>/dev/null
	if [[ -n "$default_devid" ]] ; then
		cat >> "$conffile" <<-EOF
		pcm."$default_pcm_name".type empty
		pcm."$default_pcm_name".slave.pcm "${name[$default_devid]}"
		pcm."$default_pcm_name".hint.show.@func refer
		pcm."$default_pcm_name".hint.show.name defaults.namehint.basic
		pcm."$default_pcm_name".hint.description "Default bluetooth playback"
		EOF
	fi
}

# get list of connected devices
get_devices() {
	dbus-send --print-reply --system --dest=org.bluealsa \
		/org/bluealsa org.bluealsa.Manager1.GetPCMs 2>/dev/null | gawk "$awk_parse_dbus_message"
}

handle_device_added_event() {
	if [[ "$4" = sink && "${select_profile["$3"]}" = yes ]] ; then
		add_pcm "$2" "$3" "$5" "$6" "$7"
		update_default
	fi
}

handle_device_removed_event() {
	if [[ "$4" = sink ]] ; then
		remove_pcm "$2,$3"
		update_default
	fi
}

add_initial_devices() {
	readarray -t devices < <(get_devices)
	for device in "${devices[@]}" ; do
		params=($device)
		if [[ "${params[2]}" = sink && "${select_profile["${params[1]}"]}" = yes ]] ; then
			add_pcm "${params[0]}" "${params[1]}" "${params[3]}" "${params[4]}" "${params[5]}"
		fi
	done
	update_default
}

# remove all pcms if bluealsa service terminates
handle_service_stopped_event() {
	for pcm in "${!name[@]}" ; do
		remove_pcm "$pcm"
	done
	update_default
}

# delete all stale entries from alsa config file
echo "# DO NOT DELETE, DO NOT EDIT - automatically managed by bmixd" > "$conffile"

# create a temporary named pipe to communicate with dbus monitor
PIPE=$(mktemp -u)
mkfifo $PIPE
# attach it to unused file descriptor FD
exec {FD}<>$PIPE
# unlink the named pipe
rm $PIPE

# make sure the pipeline is shut down if this script interrupted
trap "kill %1; exec {FD}>&-; handle_service_stopped_event; exit 0" INT TERM

# start dbus monitor in background
dbus-monitor --system "type='signal',sender='org.bluealsa',interface='org.bluealsa.Manager1'" "sender='org.freedesktop.DBus',member='NameOwnerChanged',arg0='org.bluealsa',arg2=''" 2>/dev/null | gawk "$awk_parse_dbus_message" >&$FD &

# load initial set of connected devices
add_initial_devices

# now listen for dbus signals
while read
do
	case "$REPLY" in
		PCMAdded*)
			handle_device_added_event $REPLY
			;;
		PCMRemoved*)
			handle_device_removed_event $REPLY
			;;
		ServiceStopped*)
			handle_service_stopped_event
			;;
	esac
done  <&$FD
