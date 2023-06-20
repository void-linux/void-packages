# This must run after locale.sh

if [ -n "$GDM_LANG" ]; then
	export LANG="$GDM_LANG"
fi
