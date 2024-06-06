#!/bin/bash

# Ensure script is run with necessary permissions
if [ "$EUID" -ne 0 ]
  then echo "Please run as root or use sudo"
  exit
fi

# Set the Istio version
ISTIO_VERSION="1.22.0"
ISTIO_DIR="istio-$ISTIO_VERSION"

# Check if istioctl is in the path
if ! command -v istioctl &> /dev/null
then
    echo "istioctl could not be found, downloading Istio..."
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
    export PATH=$PWD/$ISTIO_DIR/bin:$PATH
else
    echo "istioctl found"
fi

# Install Istio with the demo profile
echo "Installing Istio..."
istioctl install --set profile=demo -y

# Label the default namespace to enable Istio sidecar injection
echo "Labeling the default namespace for Istio sidecar injection..."
kubectl label namespace default istio-injection=enabled --overwrite

# Apply the Istio Gateway configuration
echo "Applying Istio Gateway..."
kubectl apply -f ./istio-gateway.yml

# Apply the Istio VirtualService configuration
echo "Applying Istio VirtualService..."
kubectl apply -f ./istio-virtualservice.yml

# Apply the Istio DestinationRule configuration
echo "Applying Istio DestinationRule..."
kubectl apply -f ./istio-destinationrule.yml

# Deploy the second version of the model service
echo "Deploying the second version of the model service..."
kubectl apply -f ./deployment-v2.yml

echo "Istio deployment completed."
