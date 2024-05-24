# -*- mode: ruby -*-
# vi: set ft=ruby :

# Number of worker nodes
n_workers = 2

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.box_version = "202404.23.0"
  config.ssh.username = "vagrant"
  config.ssh.password = "vagrant"
  config.ssh.insert_key = false

  # Configure the control node
  config.vm.define "controller" do |control|
    control.vm.hostname = "controller"
    control.vm.network "private_network", ip: "192.168.56.10"
    control.vm.provider "virtualbox" do |vb|
      vb.memory = 4096
      vb.cpus = 2
    end

    control.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y python3 python3-apt sshpass curl gnupg2
    SHELL

    # Provision with Ansible
    control.vm.provision "ansible" do |a|
      a.compatibility_mode = "2.0"
      a.playbook = "playbooks/general.yml"
      a.inventory_path = "inventory.ini"
    end
    control.vm.provision "ansible" do |a|
      a.compatibility_mode = "2.0"
      a.playbook = "playbooks/controller.yml"
      a.inventory_path = "inventory.ini"
    end
    control.vm.provision "ansible" do |a|
      a.compatibility_mode = "2.0"
      a.playbook = "playbooks/monitoring.yml"
      a.inventory_path = "inventory.ini"
    end
  end

  # Configure the worker nodes
  (1..n_workers).each do |i|
    config.vm.define "node#{i}" do |worker|
      worker.vm.hostname = "node#{i}"
      worker.vm.network "private_network", ip: "192.168.56.#{i + 10}"

      worker.vm.provider "virtualbox" do |vb|
        vb.memory = 4096
        vb.cpus = 2
      end

      worker.vm.provision "shell", inline: <<-SHELL
        apt-get update
        apt-get install -y python3 python3-apt sshpass curl gnupg2
      SHELL

      # Provision with Ansible
      worker.vm.provision "ansible" do |a|
        a.compatibility_mode = "2.0"
        a.playbook = "playbooks/general.yml"
        a.inventory_path = "inventory.ini"
      end
      worker.vm.provision "ansible" do |a|
        a.compatibility_mode = "2.0"
        a.playbook = "playbooks/node.yml"
        a.inventory_path = "inventory.ini"
      end
    end
  end
end
