Setting the SUID bit after install has been retired for all Wayland
compositors. It is recommended that users use a session management daemon
such as elogind or seatd and do not rely on compositors dropping privileges.

All users who require this functionality will need to set the SUID bit manually
after each update going forward.
