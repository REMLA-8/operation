#!/bin/bash

export KUBECONFIG=k3s.yaml

helm upgrade --install metallb metallb \
  --repo https://metallb.github.io/metallb \
  --namespace metallb-system --create-namespace

# Make loadbalancer available
kubectl apply -f metal-pool.yml

# Install nginx ingress controller
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# Install dashboard
helm upgrade --install kubernetes-dashboard kubernetes-dashboard \
    --repo https://kubernetes.github.io/dashboard \
    --namespace kubernetes-dashboard --create-namespace

# Make dashboard available
kubectl apply -f dashboard.yml

# Deploy application
kubectl apply -f deployment.yml