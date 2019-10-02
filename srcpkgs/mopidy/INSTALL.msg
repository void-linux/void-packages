To run mopidy as a service: edit '/etc/mopidy/mopidy.conf' and let
'media_dir' point to your music directory (readable for the system
user 'mopidy').  Then run »mopidyctl local scan« and enable the service.
Install additional extensions via python-pip.  To get a list of
extensions use »pip search Mopidy«.
See also: file:///usr/share/doc/mopidy/index.html
