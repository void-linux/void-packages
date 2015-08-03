#!/bin/sh

halfToFloat() {
	local s=$1 e=$2 m=$3
	if [ $e -eq 0 ]; then
		if [ $m -eq 0 ]; then
			# Plus or minus zero
			echo $((s << 31))
			return
		else
			# Denormalized number -- renormalize it
			while [ $((m & 0x400)) -eq 0 ]; do
				m=$((m << 1))
				e=$((e - 1))
			done
			e=$((e + 1))
			m=$((m & 0x3ff))
		fi
	elif [ $e -eq 31 ]; then
		if [ "$m" -eq 0 ]; then
			# Positive or negative infinity
			echo $(((s << 31) | 0x7f800000)) 
			return
		else
			# Nan - preserve sign and significand bits
			echo $(((s << 31) | 0x7f800000 | (m << 13)))
			return
		fi
	fi
	# Normalized number
	e=$((e + (127 - 15)))
	m=$((m << 13))
	# Assemble s, e and m
	echo $(((s << 31) | (e << 23) | m))
}


echo "//"
echo "// This is an automatically generated file."
echo "// Do not edit."
echo "//"
echo ""
echo "{"
echo -n "    "

s=0
m=0
e=0
j=0
k=0
while [ $s -lt 2 ]; do
	while [ $e -lt 32 ]; do
		while [ $m -lt 1024 ]; do
			out="$(halfToFloat $s $e $m)"
			printf "{0x%08x}, " $out
			m=$((m + 1))
			j=$((j + 1))
			if [ $j -eq 4 ]; then
				printf "\n"
				k=$((k + 1))
				[ $k -lt 16384 ] && printf "    "
				j=0
			fi
		done
		m=0
		e=$((e + 1))
	done
	e=0
	s=$((s + 1))
done
echo "};"
