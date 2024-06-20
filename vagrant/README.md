## Setup

### Vagrant

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

4. Install ansible (`pipx install ansible`). If you don't have pipx, it's probably easiest to install it using `sudo apt install pipx` (see [here](https://pipx.pypa.io/stable/) for other instructions).

5. Run `vagrant up --provision`. This will install and run kubernetes (we use the k3s distribution, which makes it much easier to connect to from an external host, we disable most of its included add-ons to make it closer to a minikube installation) on the host and agent. This is not yet very secure, as it uses the `mytoken` as a hard-coded token. It relies on the main server node being 10.10.10.100.

6. Run `./get_k8s_config.sh` to move the kubernetes config to the `k8s` folder in this repository (password is `vagrant`). If this worked, you can move the Kubernets part.

### Kubernetes

1. Install kubectl on host machine: `https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/`

2. It's recommended to move to the `k8s` folder in the repository and check if everything is running with `kubectl get services` (or similar). You can either set `export KUBECONFIG=k3s.yaml` or you can pass `--kubeconfig k3s.yaml` each time.

3. Now, a bunch of prerequisite helm charts must be installed. Due to the design of MetalLB it's not practical to package this in a single chart. In the future we will look into `helmfile` or other options. You can also erun the `./full_deploy.sh` file, which will run all of the below. It might not succeed the first time as some earlier services might not be ready. Wait a bit and re-run.

```
export KUBECONFIG=k3s.yaml

# Install MetalLB external load balancer
helm upgrade --install metallb metallb \
  --repo https://metallb.github.io/metallb \
  --namespace metallb-system --create-namespace

# Make loadbalancer available
kubectl apply -f metal-pool.yml`

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

# Deploy application (might take up to a minute before it's fully ready)
kubectl apply -f deployment.yml
```

4. If you want to access the dashboard, go to https://10.10.10.0/dash (it's important you use HTTPS, be sure to also accept the warning)

Create a service account to access it:
```
kubectl create serviceaccount jenkins
kubectl create token jenkins
# do below to grant full admin permissions specifically to service account 'jenkins'
kubectl apply -f cluster-role.yml
```

Then you can paste the resulting token into the web browser.

5. The app can be accessed at http://10.10.10.0. The backend is available at http://10.10.10.0/api.

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

6. In order to launch grafana open a new terminal run `export KUBECONFIG=k3s.yaml`. 
Then check if the kubectl is reachable with `kubectl get nodes`.

By running the following command the grafana interface will be launched
```
./prometheus/grafana_deploy.sh 
```