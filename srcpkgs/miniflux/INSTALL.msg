The miniflux database(s) are written to:

    /var/lib/miniflux

The open_basedir directive in /etc/php/php.ini needs to contain this
path to allow file operations below it.

You should also configure the process running miniflux to use
the miniflux group to be able to write to this directory.

Lastly the pdo_sqlite extension needs to be enabled in /etc/php/php.ini.
