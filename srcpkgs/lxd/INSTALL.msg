Add sub{u,g}ids for root to create unprivileged containers:

	$ echo "root:1000000:65536" | sudo tee -a /etc/subuid /etc/subgid

Start lxd service:

	$ sudo ln -s /etc/sv/lxd /var/service

Run LXD initialization:

	$ sudo lxd init

To use lxd client your user must be added to the 'lxd' group:

	$ sudo usermod -aG lxd <username>
