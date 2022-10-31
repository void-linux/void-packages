nginx has been converted to use dynamic modules.

If you used the stream or geoip modules before, you now need
to install nginx-mod-$MODULE and add this to the main context of nginx.conf:

  load_module modules/ngx_$MODULE_module.so;

