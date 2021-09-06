# Global options
complete -f -c init-checkconf -s d -l debug -d 'Show some debug output'
complete -r -F -c init-checkconf -s f -l file -d 'Path to job configuration file to check'
complete -r -F -c init-checkconf -s i -l initctl-path -d 'Path to initctl(8) binary'
complete -f -c init-checkconf -s s -l noscript -d 'Do not check script sections'
complete -r -F -c init-checkconf -s x -l startup-path -d 'Payh to startup(8) binary'
complete -f -c init-checkconf -s h -l help -d 'Display usage statement'
