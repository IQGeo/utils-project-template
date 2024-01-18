#! /bin/bash

# Fetch the server pip depdenencies
myw_product fetch pip_packages

# Fetch the client js packages
myw_product fetch node_modules

# Build the client js packages
myw_product build core_dev --debug

# build failure shouldn't halt container
true
