## Setup

1. Install Vagrant (https://developer.hashicorp.com/vagrant/downloads)

2. Install VirtualBox (https://www.virtualbox.org/wiki/Linux_Downloads)

```
curl --output virtualbox.deb https://download.virtualbox.org/virtualbox/7.0.18/virtualbox-7.0_7.0.18-162988~Ubuntu~jammy_amd64.deb
sudo apt install ./virtualbox.deb
```

3. Run `vagrant up`. The virtualbox provider is there by default. It downloads the base box (bento/ubuntu-24.04), sets it up and starts it.

4. Use `vagrant ssh` to connect.

5. Install ansible (`pipx install ansible`)

6. Install Docker Ansible role: `ansible-galaxy role install geerlingguy.docker` (currently not necessary)

7. Install kubectl on host machine: `https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/`


### On guest

1. Set correct ip `export K3S_IP=$(hostname -I | cut -d' ' -f2)`
1. Install k3s: `curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san $K3S_IP --node-ip $K3S_IP" sh -` (the tls-san option ensures you can access it from the host-only network IP)

2. Get the node-token: `sudo cat /var/lib/rancher/k3s/server/node-token`

`curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip $K3S_IP" K3S_URL=https://192.168.56.4:6443 K3S_TOKEN=K10a2d24ba749bb7a93ca0ebd931f291eceb12f0173419f4298b44942bca803693c::server:8f870ad4fbfcfa645028b455753897e5 sh -`

This will ensure it is available on the IP given by Vagrant.

`kubectl --kubeconfig k3s.yaml get pods --all-namespaces`

### Useful commands

- `vagrant suspend` and `vagrant resume` saves the state of the VM and stops it and restarts it and reloads the state, respectively. `vagrant destroy` removes the VM completely.

### Important to realize

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

### Add the 10.10.10.0 to allowed IP's for virtual box

`/etc/vbox/networks.conf`:

```
* 10.10.10.0/24 192.168.56.0/21
```


### MetalLB

https://metallb.universe.tf/

Install MetalLB 
`kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml`

Add IP addresses to pool
`kubectl apply -f metal-pool.yml`

Install nginx ingress controller
`kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml`


Dashboard:
`helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/`
`helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard`
`kubectl apply -f dashboard.yml`

Go to https://10.10.10.0/dash (it's important you use HTTPS, be sure to also accept the warning)

Create a service account to access it:
```
kubectl create serviceaccount jenkins
kubectl create token jenkins
# do below to grant full admin permissions specifically to service account 'jenkins'
kubectl apply -f cluster-role.yml
```

Then you can paste the resulting token into the web browser.