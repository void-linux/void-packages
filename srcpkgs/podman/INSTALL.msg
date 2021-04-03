`fuse-overlayfs` has been added as a runtime dependency to podman.
podman will now prefer this storage driver to the `vfs` fallback driver.
If you have existing containers that rely on the `vfs` driver, podman
will display an error and refuse any further operation.

To switch to the new storage driver, podman has to be reset:

    # podman system reset

To instead keep using the `vfs` driver, add

    [storage]
    driver="vfs"

to `/etc/containers/storage.conf` or `~/.config/containers/storage.conf`.
