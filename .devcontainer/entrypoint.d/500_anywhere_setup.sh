#!/bin/bash

# Ensure the target directories exist
mkdir -p /opt/iqgeo/anywhere/locales
mkdir -p /opt/iqgeo/anywhere/bundles
# Start Section - make direcetory for bundles
# End Section

# Copy files from different locations to /opt/iqgeo/anywhere
cp -r /opt/iqgeo/platform/WebApps/myworldapp/core/native/nativeApp.html /opt/iqgeo/anywhere/nativeApp.html
cp -r /opt/iqgeo/platform/WebApps/myworldapp/public/bundles/* /opt/iqgeo/anywhere/bundles/
cp -r /opt/iqgeo/platform/WebApps/myworldapp/public/locales/* /opt/iqgeo/anywhere/locales/
# Start Section - copy bundles to docker volumnes
# END Section
