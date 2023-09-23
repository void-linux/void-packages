The directories used by clamav have changed in versions >=1.2.0_1. This change
was made to keep the system clean and consistent with other packages.

Changes:
 - All the configuration files are now located in /etc/clamav
 - The database directory is now /lib/var/clamav

This change should be done automatically for most users and should require no
user interference.

For users already using the /etc/clamav directory for custom clamav installs,
a '.custom' extension was added to those configuration files.
