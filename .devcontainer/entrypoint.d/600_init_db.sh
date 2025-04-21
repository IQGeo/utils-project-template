#!/bin/bash
if ! myw_db $MYW_DB_NAME list versions --layout keys | grep myw_comms_schema | grep version=; then $MODULES/comms_dev_db/utils/comms_build_dev_db --database $MYW_DB_NAME; fi