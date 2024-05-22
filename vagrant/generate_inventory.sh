#!/bin/bash

# Define nodes
nodes=("controller" "node1" "node2")

# Path to the inventory template
inventory_template="inventory_template.cfg"
inventory_file="inventory.cfg"

# Function to get IP address of a node
get_ip() {
    local node=$1
    local ip=$(vagrant ssh ${node} -c "hostname -I | cut -d' ' -f2")
    echo $ip
}

# Copy template to inventory file
cp $inventory_template $inventory_file

# Update the inventory file with actual IP addresses
for node in "${nodes[@]}"; do
    ip=$(get_ip $node)
    placeholder="{{ ip_${node} }}"
    sed -i "s|$placeholder|$ip|g" $inventory_file
done