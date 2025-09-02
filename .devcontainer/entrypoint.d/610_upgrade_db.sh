#!/bin/bash

# START SECTION db upgrade - if you edit these lines manually note that your change will get lost if you run the IQGeo Project Update tool
myw_db $MYW_DB_NAME upgrade comms
echo "running upgrade script******************************************";
# END SECTION