You are installing the legacy version of radicale (1.x)!
Please install the radicale2 package for the latest (2.x) version.

If you need to migrate data, take the following steps:

- Disable the radicale 1.x service ("radicale")
- Back up the radicale 1.x collections currently in /var/lib/radicale
- Remove the old collections so they do not conflict with radicale 2.x
- Export the backup radicale 1.x collections in the 2.x format to /var/lib/radicale
  (see the radicale 1.x --export-storage CLI argument)
- Remove the radicale 1.x package ("radicale")
- Install radicale 2.x package ("radicale2")
- Enable the radicale 2.x service ("radicale")
- Confirm that the radicale 2.x service is functioning correctly and reliably
- Remove the backup radicale 1.x collections

Consider using the following resources for further guidance:

- Official radicale migration guide: https://radicale.org/1to2/.
- Void Linux Handbook, "Managing Services" section: https://docs.voidlinux.org/config/services/managing.html
