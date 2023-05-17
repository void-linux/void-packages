#!/bin/bash
# regenerates the files in icons/ from void-logo.svg
# run with ./generate-icons.sh
# only needed when the logo changes

if ! command -v rsvg-convert >/dev/null; then
    echo "Please install librsvg-utils"
    exit 1
fi

[ -d "./icons" ] && rm -r ./icons
mkdir ./icons

RESOLUTIONS="16 22 32 48 64 128 256 512"

for res in $RESOLUTIONS; do
	# at low resolutions, the text is too small to read, so the text is left out
	if [ "$res" -lt 64 ]; then
		rsvg-convert void-logo.svg --keep-aspect-ratio --width $res -i circlearcs -o ./icons/void-logo-$res.png
	else
		rsvg-convert void-logo.svg --keep-aspect-ratio --width $res -o ./icons/void-logo-$res.png
	fi
	rsvg-convert void-logo.svg --keep-aspect-ratio --width $res -i circlearcs -o ./icons/void-logo-notext-$res.png
done

# scalable
rsvg-convert void-logo.svg --format svg -o ./icons/void-logo.svg
rsvg-convert void-logo.svg --format svg -i circlearcs -o ./icons/void-logo-notext.svg

