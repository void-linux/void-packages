complete -f -c start -n "__fish_is_initctl" -a "(__fish_initctl_run list | string match --entire stop/waiting | string split ' ' -f 1)" -d Job

function __fish_is_initctl
	set -l cmd (commandline -poc)
	set -l cmd $cmd[1] # Binary
	set -l fullcmd (realpath (which $cmd))
	if [ (basename $fullcmd) = initctl ];
		return 0
	end
	return 1
end

function __fish_initctl_context -d 'Get the current startup context based on the commandline'
	if __fish_seen_argument -l user
		echo -- user
	else if __fish_seen_argument -l session
		echo -- session
	else if __fish_seen_argument -l system
		echo -- system
	else if set -q UPSTART_SESSION
		echo -- user
	else
		echo -- system
	end
end

function __fish_initctl_run -d 'Run initctl with the appropriate context'
	initctl --(__fish_initctl_context) $argv
end
