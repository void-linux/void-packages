To ensure AppArmor is enabled upon reboot add 'apparmor=1 security=apparmor' to your grub CMDLINE and rebuild your grub config with 'grub-mkconfig -o /boot/grub/grub.cfg'.
You'll also need to swith 'APPARMOR' setting in /etc/default/apparmor to your taste.
