An example configuration file was placed into /etc/corosync/ for test purpose,
with this configuration Corosync runs a 'voidlinux' cluster only locally.

For real multi-node setup, Corosync uses UDP transport between ports 5404, 5405
and 5406 for communication. If you are running a firewall, ensure that
communication on those ports are allowed between the servers.
