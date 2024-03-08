#! /bin/bash

# Fetch dependencies in case they changed since image build
myw_product fetch pip_packages
myw_product fetch node_modules

# js build was done in image, developer should start watch if needed

# build failure shouldn't halt container
true
