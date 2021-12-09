Before using the ivpn command, the ivpn-service daemon needs
to be running.

Start the ivpn-service daemon with runit:

	$ sudo ln -s /etc/sv/ivpn-service /var/service/

Then check the ivpn command (non root):

	$ ivpn status

