#!/bin/bash

## simple redis rdb backup script
## usage
## rdb-backup.sh rdb.path backup.dir bgsave.wait.seconds

rdb=${1:-"/var/db/redis/dump.rdb"}

backup_to=${2:-"/data/backup/redis/"}

wait=${3:-10} ## default wait for 10 seconds

test -f "$rdb" || {
    echo No rdb file found ; exit 1
}
test -d "$backup_to" || {
    echo Creating backup directory $backup_to && mkdir -p "$backup_to"
}

## launch bgsave
echo bgsave | redis-cli
echo "waiting for $wait seconds..."
sleep $wait
try=5
while [ $try -gt 0 ] ; do
    saved=$(echo 'info Persistence' | redis-cli | awk '/rdb_bgsave_in_progress:0/{print "saved"}')
    ok=$(echo 'info Persistence' | redis-cli | awk -F: '/rdb_last_bgsave_status:ok/{print "ok"}')
    if [[ "$saved" = "saved" ]] && [[ "$ok" = "ok" ]] ; then
        cp "$rdb" "$backup_to"
        if [ $? = 0 ] ; then
            echo "redis rdb $rdb copied to $backup_to ."
            exit 0
        else
            echo ">> Failed to copy $rdb to $backup_to !"
        fi
    fi
    try=$((try - 1))
    echo "redis maybe busy, waiting and retry in 5s..."
    sleep 5
done
exit 1
