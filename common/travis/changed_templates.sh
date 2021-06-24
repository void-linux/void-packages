#!/bin/sh
#
# changed_templates.sh

if command -v chroot-git >/dev/null 2>&1; then
	GIT_CMD=$(command -v chroot-git)
elif command -v git >/dev/null 2>&1; then
	GIT_CMD=$(command -v git)
fi

tip="$(git rev-list -1 --parents HEAD)"
case "$tip" in
	*" "*" "*) tip="${tip##* }" ;;
	*)         tip="${tip%% *}" ;;
esac

base="$(git merge-base FETCH_HEAD "$tip")" || {
	echo "Your branches is based on too old copy."
	echo "Please rebase to newest copy."
	exit 1
}

echo "$base $tip" >/tmp/revisions

/bin/echo -e '\x1b[32mChanged packages:\x1b[0m'
$GIT_CMD diff-tree -r --no-renames --name-only --diff-filter=AM \
	"$base" "$tip" \
	-- 'srcpkgs/*/template' |
	cut -d/ -f 2 |
	tee /tmp/templates |
	sed "s/^/  /" >&2
