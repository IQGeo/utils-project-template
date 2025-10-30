#!/bin/bash

log() {
  echo "[$(date '+%a %b %d %H:%M:%S.%6N %Y')] $1"
}

upgrade_database() {
if [ "${MYW_DB_UPGRADE}" == "YES" ]; then
# START SECTION db upgrade - if you edit these lines manually note that your change will get lost if you run the IQGeo Project Update tool
if myw_db $MYW_DB_NAME list versions --layout keys | grep myw_comms_schema | grep version=; then myw_db $MYW_DB_NAME upgrade comms; fi
# END SECTION
fi
}

log "Checking for shared-directory..."

if [ -n "${SHARED_DIRECTORY}" ]; then
    log "Found shared-directory attempting to lock file..."
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
