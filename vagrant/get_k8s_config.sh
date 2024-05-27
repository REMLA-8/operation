#!/bin/bash
# make sure you are in same directory as the script
cd "$(dirname "$0")"
# it's a root file and we can't get that with scp directly, so first copy it and make it accessible
vagrant ssh server-0 -c "sudo cp /etc/rancher/k3s/k3s.yaml ~/k3s.yaml && sudo chown vagrant:vagrant ~/k3s.yaml"
SRC="vagrant@10.10.10.100:~/k3s.yaml"
cd ../k8s
scp $SRC .
# we replace the localhost with the ip of the controller
sed -i "s/127.0.0.1/10.10.10.100/g" k3s.yaml