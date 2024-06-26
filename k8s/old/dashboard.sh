#!/bin/bash

export KUBECONFIG=k3s.yaml

helm upgrade --install kubernetes-dashboard kubernetes-dashboard --repo https://kubernetes.github.io/dashboard --namespace kubernetes-dashboard --create-namespace
kubectl apply -f optional/dashboard.yml