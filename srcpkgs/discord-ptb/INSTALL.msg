This template may not always be freshly up-to-date. To avoid being locked out
of Discord by a forced update check, you can modify the client's config file to
enable skipping "host" updates.
Normal UI updates will continue to function normally.

This can safely be done with this one liner, after running Discord PTB once:
(requires jq and moreutils)

_DPTB_CONFIG=~/.config/discordptb/settings.json;
 touch $_DPTB_CONFIG && \
 jq -n 'input? // {} | .SKIP_HOST_UPDATE = true' $_DPTB_CONFIG | \
 sponge $_DPTB_CONFIG
