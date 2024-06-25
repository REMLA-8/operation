#!/bin/bash

export KUBECONFIG=k3s.yaml

helm upgrade --install metallb metallb \
  --repo https://metallb.github.io/metallb \
  --namespace metallb-system --create-namespace --wait

# Make loadbalancer available
kubectl apply -f metal-pool.yml

