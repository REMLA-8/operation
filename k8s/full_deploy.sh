#!/bin/bash

./cluster/setup.sh

./app.sh

./prometheus/setup.sh

./prometheus/grafana.sh