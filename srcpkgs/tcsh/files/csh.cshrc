# Void Linux csh.cshrc

if ( -r /etc/csh.env ) then
    source /etc/csh.env
endif

set -f path = ( $path /usr/local/sbin /usr/local/bin /usr/bin /usr/sbin /sbin /bin )
