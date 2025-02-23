## void-packages buildroot containers

These containers are used for CI and should contain everything needed to run xbps-src.

### Updating

To build a new version, kick off a CI run by pushing something to `common/container/` on `master` or using the `Run workflow` button [here](https://github.com/void-linux/void-packages/actions/workflows/container.yaml).

Once this is built, update the version where it is used in `.github/workflows/` (typically in the value of a `container.image` key) to the newly-built tag.
