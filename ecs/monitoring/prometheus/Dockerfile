FROM eclipse-temurin:17-jre-alpine

ARG PROM_VERSION=3.5.4

RUN apk add --no-cache curl tar \
    && curl -L -o /tmp/prometheus.tar.gz \
       https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz \
    && tar -xzf /tmp/prometheus.tar.gz -C /tmp \
    && mv /tmp/prometheus-${PROM_VERSION}.linux-amd64/prometheus /bin/prometheus \
    && mv /tmp/prometheus-${PROM_VERSION}.linux-amd64/promtool /bin/promtool \
    && rm -rf /tmp/prometheus*

COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY cloudwatch.yml /etc/cloudwatch-exporter/cloudwatch.yml

ADD https://github.com/prometheus/cloudwatch_exporter/releases/download/v0.15.5/cloudwatch_exporter-0.15.5-jar-with-dependencies.jar /cloudwatch_exporter.jar

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 9090 9106

ENTRYPOINT ["/start.sh"]
