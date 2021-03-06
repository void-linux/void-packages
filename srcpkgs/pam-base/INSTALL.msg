WARNING: the default PAM configuration has changed. PAM 1.5.1
will remove some deprecated modules, and this can break if you
have custom configs. Please check that your PAM configuration
in /etc/pam.d doesn't use the pam_tally, pam_tally2 or
pam_lastlog (this last one only on musl systems) modules.
