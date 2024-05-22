#!/bin/bash

if [ -z "$1" ]; then
  echo "Provide host as argument!"
  exit 1
fi

# Get the IP address assigned by DHCP
ip=$(hostname -I | cut -d' ' -f2)

placeholder="{{ ip_$1 }}"

# Replace the {{ ip_ }} placeholder in the template file with the actual IP address
sed "s/$placeholder/$ip/" /vagrant/inventory_template.cfg > /vagrant/inventory.tmp


if [ -f /vagrant/ansible_inventory ]; then
  # Merge existing inventory with the new one
  grep -v -F "$node ansible_host=" /vagrant/ansible_inventory > /vagrant/ansible_inventory.bak
  cat /vagrant/ansible_inventory.tmp >> /vagrant/ansible_inventory.bak
  mv /vagrant/ansible_inventory.bak /vagrant/ansible_inventory
else
  mv /vagrant/ansible_inventory.tmp /vagrant/ansible_inventory
fi