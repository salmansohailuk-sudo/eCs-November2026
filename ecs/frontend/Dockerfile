FROM nginx:alpine

RUN rm -f /etc/nginx/conf.d/default.conf

COPY default.conf /etc/nginx/conf.d/default.conf
COPY 20-backend-url.sh /docker-entrypoint.d/20-backend-url.sh
RUN chmod +x /docker-entrypoint.d/20-backend-url.sh

COPY index.html /usr/share/nginx/html/index.html
COPY success.html /usr/share/nginx/html/success.html
COPY cancel.html /usr/share/nginx/html/cancel.html

RUN apk add --no-cache curl tar \
    && curl -L -o /tmp/nginx-exporter.tar.gz \
       https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v1.5.1/nginx-prometheus-exporter_1.5.1_linux_amd64.tar.gz \
    && tar -xzf /tmp/nginx-exporter.tar.gz -C /tmp \
    && mv /tmp/nginx-prometheus-exporter /usr/bin/nginx-exporter \
    && chmod +x /usr/bin/nginx-exporter \
    && rm -f /tmp/nginx-exporter.tar.gz

EXPOSE 80 9113

CMD ["/bin/sh", "-c", "/docker-entrypoint.d/20-backend-url.sh && nginx -g 'daemon off;' & exec nginx-exporter -nginx.scrape-uri http://127.0.0.1/nginx_status"]
