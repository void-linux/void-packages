Start lxd service:

	$ sudo ln -s /etc/sv/lxd /var/service

Run LXD initialization:

	$ sudo lxd init

To use lxd client your user must be added to the 'lxd' group:

	$ sudo usermod -aG lxd <username>
