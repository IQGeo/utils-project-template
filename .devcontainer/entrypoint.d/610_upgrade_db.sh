#!/bin/bash

if [ "${MYW_DB_UPGRADE}" == "YES" ]; then
# START SECTION db upgrade - if you edit these lines manually note that your change will get lost if you run the IQGeo Project Update tool
if myw_db $MYW_DB_NAME list versions --layout keys | grep myw_comms_schema | grep version=; then myw_db $MYW_DB_NAME upgrade comms; fi
# END SECTION
fi