# Setup

We have all tested this with basic Linux machines (16GB of RAM) running Ubuntu and Ubuntu-derived OS's (both vanilla 20.04 and 22.04 as well as Pop!_OS 22.04). We do not have access to macOS or other machines. We therefore strongly recommend using a similar setup for the host, although really any system that has `bash`, Python and other standard GNU utilities and runs VirtualBox/Vagrant should work.

## Vagrant

This setup assumes the host is running an Ubuntu-like system.

1. Install Vagrant (https://developer.hashicorp.com/vagrant/downloads)

2. Install VirtualBox (https://www.virtualbox.org/wiki/Linux_Downloads)

```
curl --output virtualbox.deb https://download.virtualbox.org/virtualbox/7.0.18/virtualbox-7.0_7.0.18-162988~Ubuntu~jammy_amd64.deb
sudo apt install ./virtualbox.deb
```

3. Enable 10.10.10.0-10.10.10.255 address range for VirtualBox. This allows us to have static IP's without worrying they interfere with other IP's on your private network. This is done by adding the following to `/etc/vbox/networks.conf` (note the 192.* part is the default):

```
* 10.10.10.0/24 192.168.56.0/21
```

NOTE: If this ip address range is not available on your local network because it is used by something else, this must be changed! This also requires changing the `k8s/cluster/metal-pool.yml` and means the app will be available at a different endpoint.

4. Install ansible (`pipx install --include-deps ansible`). If you don't have pipx, it's probably easiest to install it using `sudo apt install pipx` (see [here](https://pipx.pypa.io/stable/) for other instructions). Note that you must ensure that the directory `pipx` installs in (`~/.local/bin` for most Unix-like systems), must be on your PATH.

5. Ensure you are in the `operation/vagrant` directory.

6. Run `vagrant up --provision`. This will install and run kubernetes (we use the k3s distribution, which makes it much easier to connect to from an external host, we disable most of its included add-ons to make it closer to a minikube installation) on the host and agent. This is not yet very secure, as it uses the `mytoken` as a hard-coded token. It relies on the main server node being 10.10.10.100. Note: we have had flaky performance for this step, although it seems more machine-specific (my laptop fails more often than my PC) and not related to the provisioning. Destroying the nodes and trying again should help (or using `vagrant reload` on the specific node that is failing).

7. Run `./get_k8s_config.sh` to move the kubernetes config to the `k8s` folder in this repository (password is `vagrant`). If this worked, you can move the Kubernets part.

## Kubernetes

1. Install dependencies on the host: 

* `kubectl` on host machine: `https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/`. 
* Install `helm`: `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash`. See [here for alternative installation instructions](https://helm.sh/docs/intro/install/).
* For our Grafana deploy process, it's important `jq` and `sed` are available. See the instructions in `k8s/prometheus/README.md` for additional details.

2. Now we enter `operation/k8s` folder in the repository and check if everything is running with `kubectl get services` (or similar). You can either set `export KUBECONFIG=k3s.yaml` once per shell or you can pass `--kubeconfig k3s.yaml` each command. If everything is running, it should say something like:

```
kubernetes             ClusterIP   10.43.0.1      <none>        443/TCP    3h27m
```

3. Now, a bunch of prerequisite helm charts must be installed. Due to the design of MetalLB (it depends on specific namespaces being available) it's not practical to package this in a single chart (as this packages everything into one namespace). In the future we will look into `helmfile` or other options.

Note: all the following sub-steps can be avoided by just running `./full_deploy.sh`. That also starts Prometheus and Grafana. While this should work as we wait until the previous step is finished before moving on, in the past we have encountered some minor flakiness. If there are problems, wait a bit and re-run. The scripts are idempotent and will ensure everything is up in the desired state, so running multiple times does not cause issues. It might give errors because something is already running, but that is expected.

Note 2: the first-time setup can take a while, it might seem like it's hanging but it can take up to a minute or slightly more.

* Setup MetalLB and install Istio. This will setup all the necessary infrastructure for the deployment MetalLB allows Istio to properly give access to the cluster by handing it IP's from the range 10.10.10.0-10.10.10.99. In practice it will only use 10.10.10.0 as we need just one. This corresponds to `cluster/setup.sh`:

```bash
helm upgrade --install metallb metallb --repo https://metallb.github.io/metallb --namespace metallb-system --create-namespace --wait
kubectl apply -f metal-pool.yml

helm upgrade --install istio-base base --repo https://istio-release.storage.googleapis.com/charts --namespace istio-system --create-namespace
helm upgrade --install istiod istiod --repo https://istio-release.storage.googleapis.com/charts --namespace istio-system --create-namespace --wait
helm upgrade --install istio-ingress gateway --repo https://istio-release.storage.googleapis.com/charts --namespace istio-ingress --create-namespace --wait
```

* The pods and services for the application can now be turned on with (this corresponds to `app.sh`):

```bash
# All the kubernetes Service/Deployment definitions
kubectl apply -f application.yml
# The Istio Gateway, VirtualService, DestinationRule and other routing stuff 
kubectl apply -f ingress.yml
```

The application can be reloaded anytime by running `app.sh`. 

4. The app can be accessed at http://10.10.10.0. NOTE: Use `http`, not `https`, otherwise it will not work.

### Prometheus

After running `./full_deploy.sh` a Prometheus UI can be accessed at http://10.10.10.0/prometheus. Prometheus can also be reloaded using `./prometheus/setup.sh`. It will not autoamtically reload all configuration files, for that use the command `curl -X POST http://10.10.10.0/prometheus/-/reload`.

### Grafana

In order to automatically create and start the dashboard and alerts `jq` must be installed. On Ubuntu: `sudo apt-get install jq`. A python3 distribution is also necessary (but this should be available as Ansible also requires it). Both of these parse some of the returns from Grafana.

Furthermore the `sed` command is used to exchange placeholder uids inside of the json files. If `sed` is not working on macOS, you can install the Linux version with `brew install gnu-sed` and change it to `gsed`.

By running the following command the Grafana interface will be launched. If no contact can be made the Grafana API token will stay empty and the script will return an error. Run the deploy script with the following command:

```
./grafana.sh 
```
Then make your way to http://10.10.10.0/grafana to find Grafana, username:admin and password is returned by the `grafana_deploy` script.

ter having launched Grafana you can find the dashboard in the sidebar under dashboard->Prediction App Metrics-G8, the rules can be found under Alerting->Alert rules->Manage alert rules->Grafana-xxxxxxxx->API

The alert rules will fire in a Discord channel, which we configured as a webhook (in `json/discord_alert.json`). In a practical setup this cannot be committed to this repository as it is a secret, but for the purpose of this project this channel does not give access to anything sensitive. If more than 10 requests in a minute are made, the alert will go in a pending state and if the high request rate persists, the alert will be sent. 

### Additional use case

To enable the additional use case, run `./ratelimit/setup.sh`. This sets up a global rate limiting service that causes Isio to return a 429 error if more than 10 request per second are made the root path. It can be disabled again use `./ratelimit/disable.sh`. 

### Continuous experimentation

For details on the continuous experimentation, see the report. 

### Kubernetes Dashboard (A3)

NOTE: this only worked in the original pre-Istio A3 setup and does not work with Istio due to HTTPS issues.

The Kubernetes Dashboard is designed with HTTPS in mind. However, as we are all running our cluster locally, this clashes with the design of the dashboard. We got it working before the move to Istio, as can be seen after [this PR](https://github.com/remla24-team8/operation/pull/8). However, we decided not to include the Kubernetes Dashboard in the final product. The setup for the Kubernetes Dashboard without Istio can be found in `k8s/old`, with the following instructions (we repeat: on Istio this does not work anymore due to intricacies with the HTTPS setup!):

> If you want to access the dashboard, go to https://10.10.10.0/dash (it's important you use HTTPS, be sure to also accept the warning)

> Create a service account to access it:

```
kubectl create serviceaccount jenkins
kubectl create token jenkins
# do below to grant full admin permissions specifically to service account 'jenkins'
kubectl apply -f cluster-role.yml
```

## Notes

### Uninstall and reload

To fully reset everything, destroy and recreate the vm's using `vagrant destroy` and then go return to the setup.

However, it is easier (and faster) to run `vagrant ssh server-0` and then uninstall `k3s` using `/usr/local/bin/k3s-uninstall.sh`. After that you can run `vagrant reload --provision` and return to step 7 of "Vagrant".

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