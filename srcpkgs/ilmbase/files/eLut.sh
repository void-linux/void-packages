#!/bin/sh

eLut() {
	local i=$1
	e=$(((i & 0xff) - (127 - 15)))
	j=$((i>>8))
	if [ $e -le 0 -o $e -ge 30 ]; then
		# Special case
		echo "0"
	elif [ $j -eq 0 ]; then
		# Common case - normalized half, no exponent overflow possible
		echo $((e << 10))
	else
		echo $(((e << 10) | 0x8000))
	fi
}

echo "//"
echo "// This is an automatically generated file."
echo "// Do not edit."
echo "//"
echo ""
echo "{"
echo -n "   "

i=0
j=0
while [ $i -lt 512 ]; do
	out="$(eLut $i)"
	printf "%7s," $out
	j=$((j + 1))
	if [ $j -eq 8 ]; then
		j=0
		printf "\n"
		[ $i -lt 511 ] && printf "   "
	fi
	i=$((i + 1))
done
echo "};"
