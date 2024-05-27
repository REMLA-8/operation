#!/bin/bash
# make sure you are in same directory as the script
cd "$(dirname "$0")"
# it's a root file and we can't get that with scp directly, so first copy it and make it accessible
vagrant ssh controller -c "sudo cp /etc/rancher/k3s/k3s.yaml ~/k3s.yaml && sudo chown vagrant:vagrant ~/k3s.yaml"
# we trim any whitespace at the end and get the ip
CONTROLLER_IP=$(vagrant ssh controller -c "hostname -I | cut -d' ' -f2" | tr -d '\r')
SRC="vagrant@${CONTROLLER_IP}:~/k3s.yaml"
cd ../k8s
scp $SRC .
# we replace the localhost with the ip of the controller
sed -i "s/127.0.0.1/${CONTROLLER_IP}/g" k3s.yaml