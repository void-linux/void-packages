# Cycle detector for void-packages

This script enumerates dependencies for packages in a
[void-packages repository](https://github.com/void-linux/void-packages)
and identifies build-time dependency cycles.

For command syntax, run `xbps-cycles.py -h`. Often, it may be sufficient to run
`xbps-cycles.py` with no arguments. By default, the script will look for a
repository at `$XBPS_DISTDIR`; if that variable is not defined, the current
directory is used instead. To override this behavior, use the `-d` option to
provide the path to your desired void-packages clone.

The standard behavior will be to spawn multiple processes, one per CPU, to
enumerate package dependencies. This is by far the most time-consuming part of
the execution. To override the degree of parallelism, use the `-j` option.

Failures should be harmless but, at this early stage, unlikely to be pretty or
even helpful.
