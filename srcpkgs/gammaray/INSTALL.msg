The gdb and lldb injectors require kernel.yama.ptrace_scope to be set to 0.
This might reduce system security, as it allows regular users to inject into a non-child process.

# echo "kernel.yama.ptrace_scope=0" >> /etc/sysctl.conf
