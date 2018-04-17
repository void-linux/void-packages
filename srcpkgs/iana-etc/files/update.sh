# Adapted from https://git.archlinux.org/svntogit/packages.git/tree/trunk/PKGBUILD?h=packages/iana-etc

curl -sL https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xml |
 gawk -F"[<>]" '
/<record/ { v=n="" }
/<value/ { v=$3 }
/<name/ && $3!~/ / { n=$3 }
/<\/record/ && n && v!="" { printf "%-12s %3i %s\n", tolower(n),v,n }
' > protocols

curl -sL https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml |
 gawk -F"[<>]" '
/<updated/ && !v {v=$3; gsub("-","",v); print "version=" v >"/dev/stderr" }
/<record/ { n=u=p=c="" }
/<name/ && !/\(/ { n=$3 }
/<number/ { u=$3 }
/<protocol/ { p=$3 }
/Unassigned/ || /Reserved/ || /historic/ { c=1 }
/<\/record/ && n && u && p && !c { printf "%-15s %5i/%s\n", n,u,p }
' > services
