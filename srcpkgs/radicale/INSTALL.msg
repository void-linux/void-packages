radicale has been upgraded from 1.x to 3.x, and the radicale2 package
is now a transitional package that points to the main radicale 3.x
package. To remove radicale2 and transition to the radicale package:

    xbps-pkgdb -m manual radicale
    xbps-remove radicale2

Migration from version 1.x to 2.x and beyond is not backwards
compatible. Migration of data from 2.x to 3.x is not necessary. If you
need to migrate data from 1.x to 2.x, take the following steps:

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
