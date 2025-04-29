#!/bin/bash

# Ensure the target directories exist
mkdir -p /opt/iqgeo/anywhere/locales
mkdir -p /opt/iqgeo/anywhere/bundles
## Start Section - 
mkdir -p /opt/iqgeo/anywhere/modules/comms
mkdir -p /opt/iqgeo/anywhere/modules/comsof
## End Section

# Copy files from different locations to /opt/iqgeo/anywhere
cp -r /opt/iqgeo/platform/WebApps/myworldapp/core/native/nativeApp.html /opt/iqgeo/anywhere/nativeApp.html
cp -r /opt/iqgeo/platform/WebApps/myworldapp/public/bundles/* /opt/iqgeo/anywhere/bundles/
cp -r /opt/iqgeo/platform/WebApps/myworldapp/public/locales/* /opt/iqgeo/anywhere/locales/
## Start Section
cp -r /opt/iqgeo/platform/WebApps/myworldapp/modules/comms/public/* /opt/iqgeo/anywhere/modules/comms/
cp -r /opt/iqgeo/platform/WebApps/myworldapp/modules/custom/public/* /opt/iqgeo/anywhere/modules/custom/
## END Section
