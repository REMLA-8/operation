#!/bin/bash

./cluster/setup.sh

./app.sh

# Apply Prometheus configurations
./prometheus/setup.sh