#!/bin/bash

export KUBECONFIG=k3s.yaml

# All the kubernetes Service/Deployment definitions
kubectl apply -f application.yml
# The Istio Gateway, VirtualService, DestinationRule and other routing stuff 
kubectl apply -f ingress.yml