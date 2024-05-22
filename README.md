# Operation

In this branch we keep track of the operations on the REMLA Group 8 project.

## Overview A1

operation repo: https://github.com/REMLA-8/operation

code repo: https://github.com/REMLA-8/urlphishing/tree/a1
- This repo contains all tasks, namely dependency management, linting, the code split into files, the pipeline with DVC and metrics

## Overview A2

Operation https://github.com/remla24-team8/operation
Lib-version https://github.com/remla24-team8/lib-version
Lib-ml https://github.com/remla24-team8/lib-ml/tree/v0.1.2
model-training https://github.com/remla24-team8/model-training
model-service https://github.com/remla24-team8/model-service
app https://github.com/remla24-team8/app

Notes

Due to the absence of one of our team members and another joining halfway throughout the week, our progress has been minimal. We will make a strong comeback.
Repos that have finished work
lib-version
lib-ml
model-training
(all other repos are filled with wrappers)

## Overview A3

## Docker Compose

To test the predict:
```
curl --header "Content-Type: application/json" --request POST --data '{"url": ["google.com", "tudelft.nl"]}'  http://localhost:5000/predict
```

# Vagrant
To run the setup for creating and provisioning VMs with Vagrant and Ansible, you need to have Vagrant (https://developer.hashicorp.com/vagrant/install), Ansible (pip install ansible) and VirtualBox (https://www.virtualbox.org/wiki/Downloads) installed.

Then by running:
```
vagrant up
```
And navigate to http://192.168.56.10:5000 to see the app.

However currently we still need to add the following:
docker image name in playbooks/controller.yml
additional ansible tasks
To ensure this actually works.




