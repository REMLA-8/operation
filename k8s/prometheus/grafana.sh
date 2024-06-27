#!/bin/bash

export KUBECONFIG=k3s.yaml

#Set Unique Identifiers
PROMETHEUS_UID="prometheus-datasource-uid3"
# Set the namespace
NAMESPACE="monitoring"

# Create the namespace if it doesn't exist
kubectl create namespace $NAMESPACE || true

# Add the Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install or upgrade Grafana
helm upgrade --install grafana grafana/grafana -f prometheus/grafana-values.yml --namespace $NAMESPACE --create-namespace  --wait

kubectl apply -f prometheus/grafana.yml

echo "    "
# Retrieve the admin password
ADMIN_PASSWORD=$(kubectl get secret --namespace $NAMESPACE grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
echo "Grafana admin password: $ADMIN_PASSWORD"

# Get the Grafana pod name
POD_NAME=$(kubectl get pods --namespace $NAMESPACE -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")

# Print access instructions
echo "Grafana is accessible at http://10.10.10.0/grafana."
echo "Login with username 'admin' and the admin password retrieved above."
echo "    "

# Create Grafana API Token
GRAFANA_URL="http://10.10.10.0/grafana"

# Current date and time as a unique identifier
UNIQUE_ID=$(date +%s)

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


echo "Creating folder in Grafana..."
FOLDER_RESPONSE=$(curl -s -X POST $GRAFANA_URL/api/folders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GRAFANA_TOKEN" \
  -d "{\"title\": \"Grafana-${UNIQUE_ID}\"}")

FOLDER_UID=$(echo $FOLDER_RESPONSE | jq -r '.uid')

if [ "$FOLDER_UID" == "null" ]; then
    echo "Failed to create folder. Response was: $FOLDER_RESPONSE"
else
    echo "Folder created with UID: $FOLDER_UID"
    echo "Folder name: Grafana-${UNIQUE_ID}"
fi
echo "    "
# Prometheus service URL
PROMETHEUS_URL="http://10.10.10.0/prometheus"

# Create Prometheus datasource using Grafana API
echo "Creating Prometheus datasource in Grafana..."
curl -X POST $GRAFANA_URL/api/datasources \
  -H "Content-Type: application/json" \
  -u admin:$ADMIN_PASSWORD \
  -d '{
    "name": "Prometheus_G8",
    "type": "prometheus",
    "url": "'"$PROMETHEUS_URL"'",
    "access": "proxy",
    "isDefault": true,
    "uid": "'"$PROMETHEUS_UID"'"
  }'
echo "Prometheus datasource created successfully."
echo "    "

cp prometheus/json/grafana_dashboard.json prometheus/json/temp_grafana_dashboard.json
cp prometheus/json/alert_rules.json prometheus/json/temp_alert_rules.json
cp prometheus/json/alert_rules_canary.json prometheus/json/temp_alert_rules_canary.json

# Replace the placeholder UID in the JSON file
sed -i "s/placeholder_uid/$PROMETHEUS_UID/g" "prometheus/json/temp_grafana_dashboard.json"

# Use sed to replace the placeholder
sed -i "s/folder_placeholder_uid/$FOLDER_UID/g" "prometheus/json/temp_alert_rules.json"
# Update Prometheus datasource UID
sed -i "s/datasource_placeholder_uid/$PROMETHEUS_UID/g" "prometheus/json/temp_alert_rules.json"

# Use sed to replace the placeholder
sed -i "s/folder_placeholder_uid/$FOLDER_UID/g" "prometheus/json/temp_alert_rules_canary.json"
# Update Prometheus datasource UID
sed -i "s/datasource_placeholder_uid/$PROMETHEUS_UID/g" "prometheus/json/temp_alert_rules_canary.json"


# Deploy the dashboard
echo "Deploying dashboard..."
curl  -X POST $GRAFANA_URL/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GRAFANA_TOKEN" \
  -d @prometheus/json/temp_grafana_dashboard.json
echo "Dashboard deployed."
echo "    "
echo "Setting up contact point"
response=$(curl -X POST "$GRAFANA_URL/api/v1/provisioning/contact-points" \
   -H "Content-Type: application/json" \
   -H "Authorization: Bearer $GRAFANA_TOKEN" \
   -H "X-Disable-Provenance: true" \
   -d "@prometheus/json/discord_alert.json")
echo "Contact point set up"

echo "    "
# Deploy alert rules
echo "Deploying alert rules... This won't work with alert rules have been previously deployed. Those must be manually deleted."
curl -X POST $GRAFANA_URL/api/v1/provisioning/alert-rules \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GRAFANA_TOKEN" \
  -d @prometheus/json/temp_alert_rules.json

curl -X POST $GRAFANA_URL/api/v1/provisioning/alert-rules \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GRAFANA_TOKEN" \
  -d @prometheus/json/temp_alert_rules_canary.json
echo "    "

# Remove the temporary file after use
rm prometheus/json/temp_grafana_dashboard.json
rm prometheus/json/temp_alert_rules.json
rm prometheus/json/temp_alert_rules_canary.json