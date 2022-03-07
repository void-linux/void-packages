#!/bin/sh
#
# changed_templates.sh

if command -v chroot-git >/dev/null 2>&1; then
	GIT_CMD=$(command -v chroot-git)
elif command -v git >/dev/null 2>&1; then
	GIT_CMD=$(command -v git)
fi

/bin/echo -e '\x1b[32mFetching upstream...\x1b[0m'
$GIT_CMD fetch --depth 200 https://github.com/void-linux/void-packages.git master
