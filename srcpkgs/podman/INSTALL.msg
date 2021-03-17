`fuse-overlayfs` has been added as a runtime dependency to podman.
podman will now prefer this storage driver to the `vfs` fallback driver.

To switch to the new storage driver, podman has to be reset:

    # podman system reset

To keep the `vfs` driver, add this to `/etc/containers/storage.conf`
or `~/.config/containers/storage.conf`:

    [storage]
    driver="vfs"

Otherwise podman will display an error and refuse any further operation.

Additionally the `btrfs` storage driver has been enabled. This driver is also
available for rootless operation. Reset podman and add the following to your
`storage.conf` to switch to this driver:

    [storage]
    driver="btrfs"
