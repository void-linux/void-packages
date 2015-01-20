1. The pdo_sqlite extension needs to be enabled in /etc/php/php.ini.
2. The open_basedir directive in /etc/php/php.ini needs to contain
   /var/lib/miniflux to allow file operations below it.
3. The process running miniflux should be configured to use the miniflux
   group to be able to write to /var/lib/miniflux.
4. A cron job for the miniflux user should be configured to update feeds:
   cd /usr/share/webapps/miniflux && php cronjob.php
