#!/bin/sh
#
# changed_templates.sh

if command -v chroot-git >/dev/null 2>&1; then
	GIT_CMD=$(command -v chroot-git)
elif command -v git >/dev/null 2>&1; then
	GIT_CMD=$(command -v git)
fi

printf '%s ' "$(git merge-base FETCH_HEAD HEAD)" HEAD  > /tmp/revisions

/bin/echo -e '\x1b[32mChanged packages:\x1b[0m'
$GIT_CMD diff-tree -r --no-renames --name-only --diff-filter=AM \
	$(cat /tmp/revisions) \
	-- 'srcpkgs/*/template' |
	cut -d/ -f 2 |
	tee /tmp/templates |
	sed "s/^/  /" >&2
