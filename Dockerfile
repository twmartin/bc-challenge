FROM nginx:1.15.8-alpine

COPY docker-files/nginx.conf /etc/nginx/
COPY docker-files/bc-challenge.conf /etc/nginx/conf.d/
RUN rm /etc/nginx/conf.d/default.conf
COPY docker-files/docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
