#! /bin/bash -e

if [[ -n "${MYW_TASK_WORKERS}" && "${MYW_TASK_WORKERS}" -gt 0 ]]; then
    # Expected: start workers if MYW_TASK_WORKERS is set
    # Requires: Redis service to be running and RQ_REDIS_URL be set

    command="myw_task start --workers ${MYW_TASK_WORKERS}"
    if [[ -n "${MYW_TASK_QUEUES}" ]]; then
        command+=" --queues ${MYW_TASK_QUEUES}"
    fi
    
    $command &
    myw_task_pid="$!"

    {
        inotifywait -q -m -e close_write /run/myw_task/lrt_worker_refresh |
        while read -r filename event; do
            # Start a worker
            myw_task stop --all || myw_task stop
            $command &
            myw_task_pid="$!"
        done
    } &
fi
