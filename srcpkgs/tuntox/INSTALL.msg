The service `/etc/sv/tuntox` is not secure at all.
To use it securely, you need to add a TUNTOX_SHARED_SECRET environment variable
and share it across all your clients.

Add the file /etc/sv/tuntox/conf and export it there:

export TUNTOX_SHARED_SECRET=yourpassword
