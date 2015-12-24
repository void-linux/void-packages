Quote from the release page:

> when updating from the currently stable 1.6.x series, please bear in mind
> that your edits will be preserved during this process, but it will not be
> possible to downgrade from 2.0 to 1.6.x any more.

To avoid risking your work, backup your images and ~/.config/darktable/ or
downgrade to darktable-1.6.9:

    # xdowngrade /var/cache/xbps/darktable-1.6.9_2.x86_64.xbps
    # xbps-pkgdb -m hold darktable  
