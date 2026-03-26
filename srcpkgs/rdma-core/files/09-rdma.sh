# Load RDMA kernel modules at boot
# Equivalent to systemd's rdma-load-modules@{rdma,infiniband,roce,iwarp}.service
for conf in rdma infiniband roce iwarp; do
    [ -r "/etc/rdma/modules/${conf}.conf" ] || continue
    while read -r mod; do
        case "$mod" in
            "#"*|"") continue ;;
        esac
        modprobe -q "$mod" 2>/dev/null
    done < "/etc/rdma/modules/${conf}.conf"
done
