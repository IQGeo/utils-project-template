#!/bin/bash

#assumes database was created (300-ensure-database script)

log() {
  echo "[$(date '+%a %b %d %H:%M:%S.%6N %Y')] $1"
}

initialize_database() {
# START SECTION db init - if you edit these lines manually note that your change will get lost if you run the IQGeo Project Update tool
if ! myw_db $MYW_DB_NAME list versions --layout keys | grep myw_comms_schema | grep version=; then myw_db $MYW_DB_NAME install comms; fi
# END SECTION
}

log "Checking for shared-directory..."

if [ -n "${SHARED_DIRECTORY}" ]; then
    log "Found shared-directory attempting to lock file..."
    LOCKFILE="${SHARED_DIRECTORY}/600_init_db.lock"

    (
    if ! flock -n 200; then
        flock 200
    fi
    
    initialize_database

    ) 200>"${LOCKFILE}"
else
    log "shared-directory not found, upgrading database."
    initialize_database
fi
