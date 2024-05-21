# -*- mode: ruby -*-
# vi: set ft=ruby :

# Number of worker nodes
n_workers = 2

Vagrant.configure("2") do |config|
  # Configure the control node
  config.vm.define "controller" do |control|
    control.vm.box = "bento/ubuntu-22.04"
    control.vm.box_version = "202404.23.0"
    control.vm.hostname = "controller"
    control.vm.network "private_network", ip: "192.168.56.10"
    control.vm.provider "virtualbox" do |vb|
      vb.memory = 4096
      vb.cpus = 2
    end

    # Provision with Ansible
    control.vm.provision "ansible" do |a|
      a.compatibility_mode = "2.0"
      # a.inventory = "inventory.cfg"
      a.playbook = "playbooks/general.yml"
    end
    #Provision with Ansible
    control.vm.provision "ansible" do |a|
      a.compatibility_mode = "2.0"
      # a.inventory = "inventory.cfg"
      a.playbook = "playbooks/controller.yml"
    end
  end

  # Configure the worker nodes
  (1..n_workers).each do |i|
    config.vm.define "node#{i}" do |worker|
      worker.vm.box = "bento/ubuntu-22.04"
      worker.vm.box_version = "202404.23.0"
      worker.vm.hostname = "node#{i}"
      worker.vm.network "private_network", ip: "192.168.56.#{i + 10}"

      worker.vm.provider "virtualbox" do |vb|
        vb.memory = 4096
        vb.cpus = 2
      end

      # Provision with Ansible
      worker.vm.provision "ansible" do |a|
        a.compatibility_mode = "2.0"
        # a.inventory = "inventory.cfg"
        a.playbook = "playbooks/general.yml"
      end
      worker.vm.provision "ansible" do |a|
        a.compatibility_mode = "2.0"
        # a.inventory = "inventory.cfg"
        a.playbook = "playbooks/node.yml"
      end
    end
  end

  # Enable SSH access without port forwarding
  config.ssh.insert_key = false
end
