In order to install safe-rm and make sure that it is being picked up instead of
the usual "rm" command, make sure that you copy it in a location at the front of
your path.

For example, if your path contains:

  PATH=/usr/local/bin:/usr/bin:/bin

Then, putting safe-rm in /usr/local/bin and renaming it to "rm" will ensure that
all users on your system use safe-rm instead of the real rm.

Alternatively, symlink the safe-rm binary into a location like /usr/share/safe-rm/bin/rm
and then set the following in your shell:

  PATH="/usr/share/safe-rm/bin:$PATH"
