To enable socklog-void, start the following runit services, and
ensure no other syslogd is running:

    * socklog-unix
    * nanoklogd

Logs reside in /var/log/socklog/*, use svlogtail for simple access.

To access logs as ordinary user, add yourself to group socklog:

    $ sudo usermod -a -G socklog $USER

and then re-login to make it effective.
