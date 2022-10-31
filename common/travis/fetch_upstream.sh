#!/bin/sh
#
# changed_templates.sh

# required by git 2.35.2+
git config --global --add safe.directory "$PWD"

/bin/echo -e '\x1b[32mFetching upstream...\x1b[0m'
git fetch --depth 200 https://github.com/void-linux/void-packages.git master
