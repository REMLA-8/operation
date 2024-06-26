#!/bin/bash

./cluster/setup.sh

./app.sh

# Apply Prometheus configurations
# kubectl create namespace monitoring
# kubectl apply -f ./prometheus/clusterRole.yml -n monitoring
# kubectl apply -f ./prometheus/config-map.yml -n monitoring
# kubectl apply -f ./prometheus/prometheus-deployment.yml -n monitoring
# kubectl apply -f ./prometheus/prometheus-service.yml -n monitoring
# kubectl apply -f ./prometheus/prometheus-ingress.yml -n monitoring

