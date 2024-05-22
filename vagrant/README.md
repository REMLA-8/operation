## Setup

1. Install Vagrant (https://developer.hashicorp.com/vagrant/downloads)

2. Install VirtualBox (https://www.virtualbox.org/wiki/Linux_Downloads)

```
curl --output virtualbox.deb https://download.virtualbox.org/virtualbox/7.0.18/virtualbox-7.0_7.0.18-162988~Ubuntu~jammy_amd64.deb
sudo apt install ./virtualbox.deb
```

3. Run `vagrant up`. The virtualbox provider is there by default. It downloads the base box (bento/ubuntu-24.04), sets it up and starts it.

4. Use `vagrant ssh` to connect.

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