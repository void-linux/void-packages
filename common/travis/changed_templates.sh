#! /bin/sh
#
# changed_templates.sh

/bin/echo -e '\x1b[32mChanged packages:\x1b[0m'
git diff --name-status FETCH_HEAD...HEAD | grep "^[AM].*srcpkgs/[^/]*/template$" | cut -d/ -f 2 | tee /tmp/templates | sed "s/^/  /" >&2
