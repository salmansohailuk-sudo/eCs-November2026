#!/bin/sh
set -eu

echo "Starting CloudWatch exporter..."
java -jar /cloudwatch_exporter.jar 9106 /etc/cloudwatch-exporter/cloudwatch.yml &
CLOUDWATCH_PID=$!

echo "Starting Prometheus..."
/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus &
PROMETHEUS_PID=$!

trap 'kill $CLOUDWATCH_PID $PROMETHEUS_PID 2>/dev/null || true' TERM INT EXIT

wait -n "$CLOUDWATCH_PID" "$PROMETHEUS_PID"
EXIT_CODE=$?

kill "$CLOUDWATCH_PID" "$PROMETHEUS_PID" 2>/dev/null || true
exit "$EXIT_CODE"
