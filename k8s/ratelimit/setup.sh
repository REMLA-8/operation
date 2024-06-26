#!/bin/bash

export KUBECONFIG=k3s.yaml

kubectl apply -f ratelimit/envoy-config.yml
kubectl apply -f ratelimit/filter.yml