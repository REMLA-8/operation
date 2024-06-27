#!/bin/bash

export KUBECONFIG=k3s.yaml

kubectl delete -f ratelimit/envoy-config.yml
kubectl delete -f ratelimit/filter.yml