#%PAM-1.0
auth            requisite       pam_nologin.so
auth            required        pam_env.so
auth            required        pam_unix.so
account         required        pam_unix.so
password        required        pam_unix.so
session         required        pam_limits.so
session         required        pam_unix.so
session         optional        pam_loginuid.so
-session	optional	pam_systemd.so
