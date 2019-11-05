#!/bin/bash
source ../template

for i in $(seq -w 001 ${_bash_patchlevel}); do
	curl https://ftp.gnu.org/gnu/bash/bash-$_bash_distver-patches/bash${_bash_distver//./}-$i \
		> bash${_bash_distver//./}-${_bash_patchlevel}
done
