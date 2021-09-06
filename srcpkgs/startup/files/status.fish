complete -f -c status -n "__fish_is_initctl" -a "(__fish_initctl_list_with_status)" -d Job

function __fish_is_initctl -d 'Follow symlinks to check if given binary is initctl'
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

function __fish_initctl_list_with_status -d 'Get Job and status from initctl'
	__fish_initctl_run list \
		| cut -d ' ' -f 1-2 \
		| string replace -r ',$' '' \
		| string replace -r ' ' '\tJob: '
end
