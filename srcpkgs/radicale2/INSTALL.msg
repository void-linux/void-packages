If you want to switch from 1.x.x, there are couple steps:

- Disabling the radicale 1.x service
- (Optionally) backing up the radicale 1.x collections in /var/lib/radicale
- Moving the old collections to a location that will not conflict with radicale 2.x
- Exporting the radicale 1.x collections in the 2.x format to /var/lib/radicale
  (--export-storage path/to/empty/folder)
- Installing radicale 2.x (removing radicale 1.x)
- Enabling the radicale 2.x service
- (Optionally) removing the radicale 1.x collections once radicale 2.x service is confirmed to work

More info at http://radicale.org/1to2/