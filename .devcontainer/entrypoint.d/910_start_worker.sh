#! /bin/bash -e

if [[ -n "${TASK_WORKERS}" && "${TASK_WORKERS}" -gt 0 ]]; then
    # Expected: start workers if TASK_WORKERS is set
    # Requires: Redis service to be running and RQ_REDIS_URL be set

    command="myw_task start --workers ${TASK_WORKERS}"
    if [[ -n "${TASK_QUEUES}" ]]; then
        command+=" --queues ${TASK_QUEUES}"
    fi
    
    $command &
    myw_task_pid="$!"
fi

