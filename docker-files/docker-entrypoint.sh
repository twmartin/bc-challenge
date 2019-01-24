#!/bin/sh
echo "<html><body><p>ByteCubed Challenge $(hostname)</p></body></html>" > /usr/share/nginx/html/index.html
nginx -g 'daemon off;'
exec "$@"
