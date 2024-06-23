#!/bin/bash

# Set the namespace
NAMESPACE="monitoring"

# Create the namespace if it doesn't exist
kubectl create namespace $NAMESPACE || true

# Add the Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install or upgrade Grafana
helm upgrade --install grafana grafana/grafana --namespace $NAMESPACE --create-namespace --wait

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
ADMIN_PASSWORD=$(kubectl get secret --namespace $NAMESPACE grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
echo "Grafana admin password: $ADMIN_PASSWORD"

# Get the Grafana pod name
POD_NAME=$(kubectl get pods --namespace $NAMESPACE -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")

# Port-forward to access Grafana locally
echo "Port-forwarding Grafana to http://localhost:3000"
kubectl --namespace $NAMESPACE port-forward $POD_NAME 3000:3000 &

# Wait until port-forward is established
sleep 10

# Print access instructions
echo "Grafana is now accessible via NodePort on port 32000 of any cluster node."
echo "Access Grafana at: http://<node-ip>:32000"
echo "Login with username 'admin' and the password retrieved above."

# Create Grafana API Token
GRAFANA_URL="http://localhost:3000"

# Current date and time as a unique identifier
UNIQUE_ID=$(date +%s+h)

echo "Creating Grafana API token..."
API_RESPONSE=$(curl -s -X POST $GRAFANA_URL/api/auth/keys \
  -H "Content-Type: application/json" \
  -u admin:$ADMIN_PASSWORD \
  -d "{\"name\":\"automation-${UNIQUE_ID}\", \"role\":\"Admin\"}")

GRAFANA_TOKEN=$(echo $API_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('key', 'No token generated'))")

if [ "$GRAFANA_TOKEN" != "No token generated" ]; then
    echo "Generated Grafana API token: $GRAFANA_TOKEN"
else
    echo "Failed to generate Grafana API token. Response was: $API_RESPONSE"
    exit 1
fi

# Prometheus service URL
PROMETHEUS_URL="http://prometheus-service.monitoring.svc.cluster.local:8080"

# Create Prometheus datasource using Grafana API
echo "Creating Prometheus datasource in Grafana..."
curl -X POST $GRAFANA_URL/api/datasources \
  -H "Content-Type: application/json" \
  -u admin:$ADMIN_PASSWORD \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "'"$PROMETHEUS_URL"'",
    "access": "proxy",
    "isDefault": true
  }'
echo "Prometheus datasource created successfully."

# Deploy the dashboard
echo "Deploying dashboard..."
curl -v -X POST $GRAFANA_URL/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GRAFANA_TOKEN" \
  -d @prometheus/grafana_dashboard.json
echo "Dashboard deployed."

# Deploy alert rules
echo "Deploying alert rules..."
curl -X POST $GRAFANA_URL/api/ruler/grafana/api/v1/rules \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GRAFANA_TOKEN" \
  -d @prometheus/alert-rules.json
echo "Alert rules deployed."
