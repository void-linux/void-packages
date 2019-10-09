A self-signed certificate for SSL has been created automatically, but
this should be created again with proper settings in dovecot-openssl.cnf:

	$ rm -f /etc/ssl/{certs,private}/dovecot.pem
	$ [edit /etc/ssl/dovecot-openssl.cnf]
	$ /usr/bin/dovecot-mkcert.sh
