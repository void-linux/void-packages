Dynamic modules are loaded into NGINX with the `load_module` directive. Place
the following line at the top of /etc/nginx/nginx.conf:

load_module /usr/lib/nginx/ngx_http_headers_more_filter_module.so;
