# vim: set ts=4 sw=4 et:
#
# This hook executes the following tasks:
#	- Looks on PKGDESTDIR/etc for files that should be in conf_files=

hook() {
    local cfp

    if [ ! -d $PKGDESTDIR/etc ]; then
        return 0
    fi

    # Process conf_files and replaces
    # occurences of globs with a leading slash
    if [ -n "$conf_files" ]; then
        cfp="$conf_files"
        cfp="${cfp//\*/}"
    fi

    for cf in $(find $PKGDESTDIR/etc -type f); do
        case "${cf#$PKGDESTDIR}" in
            /etc/sv*)
                continue
                ;;
            /etc/kernel.d*)
                continue
                ;;
            /etc/cron.*)
                continue
                ;;
            /etc/ssl*)
                continue
                ;;
            *)
                cf="${cf#$PKGDESTDIR}"

                if [ -n "$cfp" ]; then
                    if [[ "$cfp" == *"$cf"* ]]; then
                        continue
                    fi

                    if grep -q "^${cf%/*}/$" <<< "${cfp// /$'\n'}"; then
                        continue
                    fi
                fi

                msg_warn "$cf should be in conf_files=\n"
                ;;
        esac
    done
}
