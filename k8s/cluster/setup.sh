#!/bin/bash

export KUBECONFIG=k3s.yaml

helm upgrade --install metallb metallb --repo https://metallb.github.io/metallb --namespace metallb-system --create-namespace --wait
kubectl apply -f cluster/metal-pool.yml
helm upgrade --install istio-base base --repo https://istio-release.storage.googleapis.com/charts --namespace istio-system --create-namespace
helm upgrade --install istiod istiod --repo https://istio-release.storage.googleapis.com/charts --namespace istio-system --create-namespace --wait
helm upgrade --install istio-ingress gateway --repo https://istio-release.storage.googleapis.com/charts --namespace istio-ingress --create-namespace --wait