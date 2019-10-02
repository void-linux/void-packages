To enable ${PKGNAME} in the Apache HTTP server, add the following line
into /etc/httpd/httpd.conf:

	LoadModule wsgi_module modules/mod_wsgi.so

and reload the Apache daemon with:

	# sv restart apache

