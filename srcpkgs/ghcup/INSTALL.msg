ghcup comes with an internal downloader, but optionally depends on curl and/or
wget for more advanced usages (e.g., proxying).  To use curl/wget as downloader,
first make sure they are installed, then run `ghcup config set downloader Curl`.

Also, ghcup requires $GHCUP_INSTALL_BASE_PREFIX/.ghcup/bin to be in your PATH
(by default, $GHCUP_INSTALL_BASE_PREFIX is $HOME); make sure to update your
shell launch scripts accordingly. Alternatively, when GHCUP_USE_XDG_DIRS is set,
GHCUP uses XDG-ish directories.
