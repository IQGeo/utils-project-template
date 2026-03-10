#!/bin/bash

if [ "${MYW_DB_UPGRADE}" == "YES" ]; then
# START SECTION db upgrade - if you edit these lines manually note that your change will get lost if you run the IQGeo Project Update tool
if myw_db $MYW_DB_NAME list versions --layout keys | grep mywmywwfm_schema | grep version=; then myw_db $MYW_DB_NAME upgrade workflow_manager; fi
# END SECTION
fi