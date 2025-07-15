#!/bin/bash

# Ensure the target directories exist
mkdir -p /opt/iqgeo/anywhere/locales
mkdir -p /opt/iqgeo/anywhere/bundles
# START SECTION - make directory for bundles
mkdir -p /opt/iqgeo/anywhere/modules/custom
mkdir -p /opt/iqgeo/anywhere/modules/comms
mkdir -p /opt/iqgeo/anywhere/modules/comms_cloud
mkdir -p /opt/iqgeo/anywhere/modules/comsof
mkdir -p /opt/iqgeo/anywhere/modules/workflow_manager
mkdir -p /opt/iqgeo/anywhere/modules/wfm_nmt
mkdir -p /opt/iqgeo/anywhere/modules/comms_dev_db
mkdir -p /opt/iqgeo/anywhere/modules/comsof_dev_db
mkdir -p /opt/iqgeo/anywhere/modules/workflow_manager_dev_db
# END SECTION

# Copy files from different locations to /opt/iqgeo/anywhere
cp -r /opt/iqgeo/platform/WebApps/myworldapp/core/native/nativeApp.html /opt/iqgeo/anywhere/nativeApp.html
cp -r /opt/iqgeo/platform/WebApps/myworldapp/public/bundles/* /opt/iqgeo/anywhere/bundles/
cp -r /opt/iqgeo/platform/WebApps/myworldapp/public/locales/* /opt/iqgeo/anywhere/locales/
# START SECTION - copy bundles to docker volumes
cp -r /opt/iqgeo/platform/WebApps/myworldapp/modules/custom/public/* /opt/iqgeo/anywhere/modules/custom/
cp -r /opt/iqgeo/platform/WebApps/myworldapp/modules/comms/public/* /opt/iqgeo/anywhere/modules/comms/
cp -r /opt/iqgeo/platform/WebApps/myworldapp/modules/comms_cloud/public/* /opt/iqgeo/anywhere/modules/comms_cloud/
cp -r /opt/iqgeo/platform/WebApps/myworldapp/modules/comsof/public/* /opt/iqgeo/anywhere/modules/comsof/
cp -r /opt/iqgeo/platform/WebApps/myworldapp/modules/workflow_manager/public/* /opt/iqgeo/anywhere/modules/workflow_manager/
cp -r /opt/iqgeo/platform/WebApps/myworldapp/modules/wfm_nmt/public/* /opt/iqgeo/anywhere/modules/wfm_nmt/
cp -r /opt/iqgeo/platform/WebApps/myworldapp/modules/comms_dev_db/public/* /opt/iqgeo/anywhere/modules/comms_dev_db/
cp -r /opt/iqgeo/platform/WebApps/myworldapp/modules/comsof_dev_db/public/* /opt/iqgeo/anywhere/modules/comsof_dev_db/
cp -r /opt/iqgeo/platform/WebApps/myworldapp/modules/workflow_manager_dev_db/public/* /opt/iqgeo/anywhere/modules/workflow_manager_dev_db/
# END SECTION