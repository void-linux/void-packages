#!/bin/sh
#
# changed_templates.sh

/bin/echo -e '\x1b[32mFetching upstream...\x1b[0m'
git fetch --depth 200 git://github.com/void-linux/void-packages.git master
