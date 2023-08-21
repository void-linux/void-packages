GnuPG 2.3 changes the behaviour of scdaemon. While GnuPG 2.2 had a fallback to
PC/SC when the internal CCID driver didn't work, the fallback now has to be
explicitly configured by disabling the internal CCID driver. If you've not
explicitly enabled pcscd, you shouldn't need to do anything. For more details,
see https://docs.voidlinux.org/config/gnupg.html
