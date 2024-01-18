#!/bin/bash

echo "Checking if database '$MYW_DB_NAME' exists"
if ! myw_db $MYW_DB_NAME list; 
then 
    # wait 5 seconds and try again in case it was just postgis starting up
    sleep 5
    if ! myw_db $MYW_DB_NAME list; then 
        myw_db $MYW_DB_NAME create
        myw_db $MYW_DB_NAME install core
        myw_db $MYW_DB_NAME install comms
    fi
fi

