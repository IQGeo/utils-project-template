#!/bin/bash

upgrade_database() {
if [ "${MYW_DB_UPGRADE}" == "YES" ]; then
# START SECTION db upgrade - if you edit these lines manually note that your change will get lost if you run the IQGeo Project Update tool
if myw_db $MYW_DB_NAME list versions --layout keys | grep myw_comms_schema | grep version=; then myw_db $MYW_DB_NAME upgrade comms; fi
# END SECTION
fi
}

if [ -n "${SHARED_DIRECTORY}" ]; then
    log "Found shared-directory, attempting to lock 610_upgrade_db..."
    LOCKFILE="${SHARED_DIRECTORY}/610_upgrade_db.lock"
    (
    if ! flock -n 200; then
        flock 200
    fi
    
    upgrade_database

    ) 200>"${LOCKFILE}"
else
    log "shared-directory not found, upgrading database."
    upgrade_database
fi
