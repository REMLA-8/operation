# Setup

## Vagrant

This setup assumes the host is running an Ubuntu-like system.

1. Install Vagrant (https://developer.hashicorp.com/vagrant/downloads)

2. Install VirtualBox (https://www.virtualbox.org/wiki/Linux_Downloads)

```
curl --output virtualbox.deb https://download.virtualbox.org/virtualbox/7.0.18/virtualbox-7.0_7.0.18-162988~Ubuntu~jammy_amd64.deb
sudo apt install ./virtualbox.deb
```

3. Enable 10.10.10.0-10.10.10.255 address range for VirtualBox. This allows us to have static IP's without worrying they interfere with other IP's on your private network. This is done by adding the following to `/etc/vbox/networks.conf`:

```
* 10.10.10.0/24 192.168.56.0/21
```

NOTE: If this ip address range is not available on your local network because it is used by something else, this must be changed! This also requires changing the `k8s/cluster/metal-pool.yml` and means the app will be available at a different endpoint.

4. Install ansible (`pipx install --include-deps ansible`). If you don't have pipx, it's probably easiest to install it using `sudo apt install pipx` (see [here](https://pipx.pypa.io/stable/) for other instructions). Note that you must ensure that the directory `pipx` installs in (`~/.local/bin` for most Unix-like systems), must be on your PATH.

5. Ensure you are in the `operation/vagrant` directory.

6. Run `vagrant up --provision`. This will install and run kubernetes (we use the k3s distribution, which makes it much easier to connect to from an external host, we disable most of its included add-ons to make it closer to a minikube installation) on the host and agent. This is not yet very secure, as it uses the `mytoken` as a hard-coded token. It relies on the main server node being 10.10.10.100. Note: we have had flaky performance for this step, although it seems more machine-specific (my laptop fails more often than my PC) and not related to the provisioning. Destroying the nodes and trying again should help.

7. Run `./get_k8s_config.sh` to move the kubernetes config to the `k8s` folder in this repository (password is `vagrant`). If this worked, you can move the Kubernets part.

## Kubernetes

1. Install kubectl on host machine: `https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/`

2. Instal `helm`: `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash`. See [here for alternative installation instructions](https://helm.sh/docs/intro/install/).

3. It's recommended to move to the `k8s` folder in the repository and check if everything is running with `kubectl get services` (or similar). You can either set `export KUBECONFIG=k3s.yaml` once per shell or you can pass `--kubeconfig k3s.yaml` each command. If everything is running, it should say something like:

```
kubernetes             ClusterIP   10.43.0.1      <none>        443/TCP    3h27m
```

4. Now, a bunch of prerequisite helm charts must be installed. Due to the design of MetalLB (it depends on specific namespaces being available) it's not practical to package this in a single chart (as this packages everything into one namespace). In the future we will look into `helmfile` or other options.

Note: all the following sub-steps can be avoided by just running `./full_deploy.sh`. It might not succeed the first time as some earlier services might not be ready. Wait a bit and re-run. We have tried to make everything wait before continuing, but this is not guaranteed to work. So be patient and run it a few times if necessary. It might not succeed the first time as some earlier services might not be ready. Wait a bit and re-run. We have tried to make everything wait, but this is not guaranteed to work. So be patient and run it a few times if necessary.

* Setup MetalLB and install Istio. This will setup all the necessary infrastructure for the deployment MetalLB allows Istio to properly give access to the cluster by handing it IP's from the range 10.10.10.0-10.10.10.99. In practice it will only use 10.10.10.0 as we need just one. This corresponds to `cluster/setup.sh`:

```bash
helm upgrade --install metallb metallb --repo https://metallb.github.io/metallb --namespace metallb-system --create-namespace --wait
kubectl apply -f metal-pool.yml

helm upgrade --install istio-base base --repo https://istio-release.storage.googleapis.com/charts --namespace istio-system --create-namespace
helm upgrade --install istiod istiod --repo https://istio-release.storage.googleapis.com/charts --namespace istio-system --create-namespace --wait
helm upgrade --install istio-ingress gateway --repo https://istio-release.storage.googleapis.com/charts --namespace istio-ingress --create-namespace --wait
```

* The pods and services for the application can now be turned on with:

```bash
# All the kubernetes Service/Deployment definitions
kubectl apply -f application.yml
# The Istio Gateway, VirtualService, DestinationRule and other routing stuff 
kubectl apply -f ingress.yml
```

5. The app can be accessed at http://10.10.10.0.

### Dashboard

The Kubernetes Dashboard is designed with HTTPS in mind. However, as we are all running our cluster locally, this clashes with the design of the dashboard. We got it working before the move to Istio, as can be seen after [this PR](https://github.com/remla24-team8/operation/pull/8). However, since there is already the Kiali Dashboard, we decided not to include the Kubernetes Dashboard in the final product. The setup without Istio can be found in `k8s/old`.

### Prometheus

When needing port forwarding write the following line in the terminal to expose the prometheus service.

```
kubectl port-forward -n monitoring svc/prometheus-service 8080:8080
```
In order to launch grafana open a new terminal run `export KUBECONFIG=k3s.yaml`. 
Then check if the kubectl is reachable with `kubectl get nodes`.

Make sure jq is installed on a linux system. `sudo apt-get install jq`.

If `sed` is not working on macOS, you can install the Linux version with `brew install gnu-sed` and change it to `gsed`.

By running the following command the grafana interface will be launched, please make sure localhost:3000 is free first or change the portforwarding in the grafana deploy file. If no contact can be made the grafana API token will stay empty and the script will return an error. To solve make sure localhost:3000 is free or change the port in the grafan deploy script.
```
./prometheus/grafana_deploy.sh 
```
Then make your way to http://localhost:3000/ to find grafana, username:admin and password is returned by the grafana_deploy script.

The Alert rules will fire in a discord channel. 

### Kiali Dashboard

## Notes

### Vagrant networking addendum

By default, Vagrant will set up a NAT adapter with VirtualBox (https://www.virtualbox.org/manual/ch06.html#network_nat). This is used by e.g. `vagrant ssh` to always have a way to communicate with the guest VM. What NAT does is that the VirtualBox engine acts as a router mapping traffic from and to the VM. 

To allow connections with SSH, it will automatically forward a port: which is roughly equivalent to the following config line `config.vm.network "forwarded_port", guest: 22, host: <some available port>`. 

During setup it will say to what port it was bound on the host. If it was 2222, you can then connect with:

`ssh -p 2222 vagrant@127.0.0.1` (password 'vagrant')

#### Host-only network

You can also set-up a host-only network:

```
# replace type: "dhcp" with ip: "192.168.56.<whatever you want>" to create a static IP
# note that this IP must be free on the host network!
config.vm.network "private_network", type: "dhcp"
```

This is useful because it does not require setting up port forwarding for every service, as anyone on the host can now talk to the nodes, as well as the nodes with each other (because they have a single address on the host).


6. 
