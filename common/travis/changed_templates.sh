#!/bin/sh
#
# changed_templates.sh

ci_check=$( echo -e "$PR_TITLE\n$PR_BODY" |
	sed -ne 's/.*\[ci \+check \+\([^]]*[^ ]\) *].*/\1/p' )

tip="$(git rev-list -1 --parents HEAD)"
case "$tip" in
	# This is a merge commit, pick last parent
	*" "*" "*) tip="${tip##* }" ;;
	# This is a non-merge commit, pick itself
	*)         tip="${tip%% *}" ;;
esac

base="$(git merge-base origin/HEAD "$tip")"

[ $(git rev-list --count "$tip" "^$base") -lt 200 ] || {
	echo "::error title=Branch out of date::Your branch is too out of date. Please rebase on upstream and force-push."
	exit 1
}

echo "$base $tip" >/tmp/revisions

/bin/echo -e '\x1b[32mChanged packages:\x1b[0m'
git diff-tree -r --no-renames --name-only --diff-filter=AM \
	"$base" "$tip" \
	-- 'srcpkgs/*/template' |
	cut -d/ -f 2 |
	xargs ./xbps-src sort-dependencies |
	tee /tmp/templates |
	sed "s/^/  /" >&2

if [ -n "$ci_check" ]; then
	/bin/echo -e '\x1b[32mAdditional packages to build and check:\x1b[0m'
	printf "%s\n" $ci_check |
		xargs ./xbps-src sort-dependencies |
		tee -a /tmp/templates |
		sed "s/^/  /" >&2
fi
