#!/bin/bash

export KUBECONFIG=k3s.yaml

kubectl create namespace monitoring
kubectl apply -f ./prometheus/clusterRole.yml -n monitoring
kubectl apply -f ./prometheus/config-map.yml -n monitoring
kubectl apply -f ./prometheus/prometheus-deployment.yml -n monitoring
kubectl apply -f ./prometheus/prometheus-service.yml -n monitoring
# kubectl apply -f ./prometheus/prometheus-istio.yml -n monitoring