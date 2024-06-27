# Operation

Welcome to the main README of the project for REMLA Team 8 2024.

## Repositories

- [`operation](https://github.com/remla24-team8/operation)
- [`lib-version`](https://github.com/remla24-team8/lib-version)
- [`lib-ml`](https://github.com/remla24-team8/lib-ml)
- [`model-training`](https://github.com/remla24-team8/model-training) 
- [`model-service`](https://github.com/remla24-team8/model-service)
- [`app-backend`](https://github.com/remla24-team8/app-service)
- [`app-frontend`](https://github.com/remla24-team8/app-frontend)

Below we will write per assignment how the rubrics can be assessed. At the end the setup instructions for Docker Compose and Kubernetes are discussed.

## Overview A1

**Project best practices**: See `model-training` and its README. This also contains detailed instructions on how to install dependencies throughout our project. We have a shared tokenizer component, so we aim for excellent.

**Pipeline management**: See `model-training` and its README. It creates a `metrics.json` and this can be viewed with `dvc exp show` after running `dvc rerpo`. We aim for excellent.

**Code quality**: See the GitHub workflows in the different repositories. We have linters setup throughout our project and we ensure they are also followed. 

## Overview A2

**Automated Release Process**: Inspect the GitHub workflows in the different repositories. Releases can be created from GitHub for all the libraries and containers and they are automatically uploaded, either to PyPI or to GHCR.

**Software Reuse in Libraries**: See the `lib-ml`, `lib-version` repositories. We have `lib-ml` and `lib-version` released on PyPI. `lib-version` automatically returns its own version. `lib-ml` is used for both training and the model service.

**Exposing a Model via REST**: Inspect the `model-service` repository. Model is stored outside the image, containers with Flask application are automatically built. Note that the container image is still very big because it includes dependencies like Tensorflow, which are very large in size and smaller versions don't support all the functionality we need.

**Sensible Use Case**: Inspect the `app-frontend` repository. We built a good-looking application that also allows sending multiple queries at once and returns the prediction in a nice format. These interactions and also whether or not the percentage is high is stored by the backend.

**Docker Compose Operation**: Inspect `docker-compose.yml` in the `operation` repository and see the Docker Compose section in this readme. Also inspect the automated tests run in that repository, which use the Compose setup. 

## Overview A3

**Setting up (Virtual) Infrastructure**. See the `vagrant` directory in this repository and its README. It uses an Ansible playbook to setup Kubernetes automatically. The Vagrantfile takes a list of agents and nodes to set up.

**Setting up Software Environment**: For Kubernetes Dashboard, inspect this https://github.com/remla24-team8/operation/pull/8 and see the comment in `vagrant/README.md`. See that README also for setup instruction. WE use Deployment and ConfigMap for Prometheus, Grafana, which are available directly using Istio at 10.10.10.0 (again see the README).

**Kubernetes & Monitoring**: Everything is directly accessible at the main IP using Istio, see the README in `vagrant`. The deployment happens idempotently using a single deploy script.

**App Monitoring**: Multiple metrics are included in Grafana and we use a Discord alert rule. Setup using `vagrant/README.md` and go to 10.10.10.0/grafana.

**Grafana**: Setup using `vagrant/README.md` and go to 10.10.10.0/grafana. Everything is installed using a single command using Helm and Kubernetes configurations in an idempotent way. It contains a number of visualizations.

## Overview A4

**Automated Tests**: See `model-training` for the tests and instructions. 

**Continuous Training**: See `model-training` for the tests and instructions. 

## Overview A5

**Traffic Management**: Setup using `vagrant/README.md` and reload a few times to see the 70/30 weight (for exposition purposes the background color is different). We chose to not have a stable routing because without a full DNS/reverse proxy setup on an actual server it is hard to actually get any information about the user/client (like their IP address) that is stable.

**Continuous Experimentation**: Prometheus continuously scrapes metrics, which are described in the report.

**Additional Use Case**: A rate limit service can be enabled to ensure the cluster does not get overloaded.

## Docker Compose

Run the project using `docker compose up`. The frontend is available at `localhost:3000`.

To test the predict:
```
curl --header "Content-Type: application/json" --request POST --data '{"url": ["google.com", "tudelft.nl"]}'  http://localhost:5000/predict
```

## Vagrant

See the README in `vagrant/README.md` for instructions on how to set up Kubernetes.

Once it is started, you can access:

- The app at `http://10.10.10.0`
- Prometheus at `http://10.10.10.0/prometheus`
- Grafana at `http://10.10.10.0/grafana`

In a real setup these would be on separate domains, but without a full reverse proxy DNS setup in this course we decided to put them on different subpaths instead.
