# Prometheus and Grafana Setup on Kubernetes
**This is not necessary if you have followed the readme in the vagrant folder.**

## Prerequisites
- A running Kubernetes cluster
- `kubectl` configured
- Helm installed

# Setup Instructions

### 1. Full Deployment Script
Use the provided `full_deploy.sh` script to automate the deployment of Prometheus, Grafana, and your application.

Run the script

```
chmod +x full_deploy.sh
sudo ./full_deploy.sh
```
### 2. Access Prometheus Dashboard

    Port Forwarding:

```
    kubectl port-forward -n monitoring svc/prometheus-service 9090:8080

    
```
Access Prometheus at http://localhost:9090.

### 3. Access Grafana Dashboard

Get Grafana Admin Password:

```
kubectl get secret --namespace monitoring -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Port Forward to Access Grafana:

```

    export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
    kubectl --namespace monitoring port-forward $POD_NAME 3000
```

Access Grafana at http://localhost:3000.

Login to Grafana:
Username: admin
Password: Retrieved in the previous step

### 4. Configure Grafana Dashboard

Add Prometheus Data Source:
Go to Grafana Home.
Click on Configuration > Data Sources.
Click Add data source.
Select Prometheus.
Set the URL to http://prometheus-service.monitoring.svc.cluster.local:8080.
Click Save & Test.

Import Dashboard:
Click on + > Import.
Upload the prometheus/grafana_dashboard.json file or copy the JSON content.
Click Load.
