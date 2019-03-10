(taken verbatim from quassel's release announcement)
https://quassel-irc.org/node/134

Before you upgrade, please be aware that both the database schema and the
config file formats have been updated since 0.12. Quassel will automatically
upgrade both once the new version is started for the first time, however no
rollback is possible, so do make a backup before starting the new version! The
upgrade may take a long time (up to several hours) if your database is
(un)reasonably large, during which the core or mono client cannot be used. The
upgrade may also temporarily require up to double the disk space. Do not
interrupt the upgrade process, otherwise your database may become corrupted!
