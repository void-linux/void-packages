WARNING: PAM>=1.5.0 has removed the pam_tally and pam_tally2 modules,
as well as the pam_lastlog module on musl. If you have a custom PAM
config, you will need to fix it immediately for these changes.

Otherwise, the pam-base-0.4 update will have handled these changes for
you, unless your XBPS config uses "keepconf=true",
"preserve=/etc/pam.d/system-login" or "preserve=/etc/pam.d/*".
