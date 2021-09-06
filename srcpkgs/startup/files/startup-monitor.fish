# Global options
complete -x -c startup-monitor -s d -l destination -d 'Which endpoint to connect to' -a "session-socket session-system system-socket system-bus"
complete -f -c startup-monitor -s h -l help -d 'Show brief usage summary'
complete -f -c startup-monitor -s n -l no-gui -d 'Run in command-line mode'
complete -x -c startup-monitor -s s -l separator -d 'Specify alternate field separator for command-line output'
