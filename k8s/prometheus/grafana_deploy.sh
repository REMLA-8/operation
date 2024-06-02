#!/bin/bash

# Set the namespace
NAMESPACE="monitoring"

# Create the namespace if it doesn't exist
kubectl create namespace $NAMESPACE || true

# Add the Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install or upgrade Grafana
helm upgrade --install grafana grafana/grafana --namespace $NAMESPACE --create-namespace

# Create a NodePort service for Grafana
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: $NAMESPACE
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 3000
    nodePort: 32000
  selector:
    app.kubernetes.io/name: grafana
EOF

# Retrieve the admin password
echo "Retrieving the Grafana admin password..."
ADMIN_PASSWORD=$(kubectl get secret --namespace $NAMESPACE grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
echo "Grafana admin password: $ADMIN_PASSWORD"

# Get the Grafana pod name
POD_NAME=$(kubectl get pods --namespace $NAMESPACE -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")

# Port-forward to access Grafana locally (optional, for local access testing)
echo "Port-forwarding Grafana to http://localhost:3000"
kubectl --namespace $NAMESPACE port-forward $POD_NAME 3000:3000 &

# Print access instructions
echo "Grafana is now accessible via NodePort on port 32000 of any cluster node."
echo "Access Grafana at: http://<node-ip>:32000"
echo "Login with username 'admin' and the password retrieved above."

# Optionally, you can provide the URL and login details to your teammates
