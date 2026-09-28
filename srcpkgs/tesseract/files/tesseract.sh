#!/bin/sh
TESS_BIN=/usr/bin/
TESS_DATA=/usr/share/tesseract/
TESS_OPTIONS="-u$HOME/.tesseract"
cd "$TESS_DATA"
exec "$TESS_BIN/tesseract-client" "$TESS_OPTIONS" "$@"
