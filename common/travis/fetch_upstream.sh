#!/bin/sh
#
# changed_templates.sh

/bin/echo -e '\x1b[32mFetching upstream...\x1b[0m'
echo $(pwd)
echo $HOME
cat $HOME/.gitconfig
git fetch --depth 200 https://github.com/void-linux/void-packages.git master
