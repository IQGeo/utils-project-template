#! /bin/bash

# Fetch dependencies. will include those specified in repo, which can't be saved in the container image
myw_product fetch pip_packages

# fetch node_modules and watch start only on container start, defined in devcontainer.json, so that it runs as iqgeo user

# failure shouldn't halt container
true
