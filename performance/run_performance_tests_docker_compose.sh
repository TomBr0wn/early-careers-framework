#!/bin/bash

export RAILS_ENV=performance

export SERVICE_NAME=early-careers-framework
export DATABASE_NAME=early_careers_framework_${RAILS_ENV}

export IMAGE=ghcr.io/dfe-digital/early-careers-framework:main

export PERF_SCENARIO=api-smoke-test

export PERF_REPORT_FILE=k6-output.json

mkdir ../reports
rm -fr ../reports/${PERF_SCENARIO}*

tar -zxvf ./db/sanitised-production.sql.gz -C ./db sanitised-production.sql

docker compose up -d web
sleep 1

docker compose exec -T db createdb --username postgres early_careers_framework_performance
docker compose exec -T db createdb --username postgres early_careers_framework_analytics_performance
docker compose exec -T db psql --username postgres early_careers_framework_performance < ./db/sanitised-production.sql
docker compose exec web bundle exec rails db:migrate db:seed

docker compose up k6
docker compose cp k6:/home/k6/k6-output.json ../reports/${PERF_SCENARIO}-report.json
docker compose cp k6:/home/k6/k6.log ../reports/${PERF_SCENARIO}.log

node dfe-k6-log-to-json.js ../reports ${PERF_SCENARIO}
node dfe-k6-reporter.js ../reports ${PERF_SCENARIO}

docker compose down -v
rm -fr ./db/sanitised-production.sql
