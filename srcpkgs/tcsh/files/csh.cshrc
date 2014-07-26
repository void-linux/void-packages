# Void Linux csh.cshrc

if ( -r /etc/csh.env ) then
    source /etc/csh.env
endif

set -f path = ( $path /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin /bin /sbin )
