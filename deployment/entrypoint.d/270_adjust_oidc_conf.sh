#!/bin/bash

# replace references to the application base URL in the oidc configuration file
sed -i "s|{myw_ext_base_url}|${MYW_EXT_BASE_URL}|g" /opt/iqgeo/config/oidc/conf.json
# replace references to the keycloak URL in the oidc configuration file
sed -i "s|http://keycloak.local:8080|${KEYCLOAK_URL}|g" /opt/iqgeo/config/oidc/conf.json