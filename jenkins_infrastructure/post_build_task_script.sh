#!/bin/bash

# Script for shutting down any processes running on slaves in Jenkins

# Protected PIDS
PROPID=($(ps -ef | grep -v grep | grep "jar slave.jar" | awk '{print $2}'))
PROPID+=($BASHPID)
printf '%s %s %s \n' "Protected PIDS are: ${PROPID[@]}"

# FIND PGID
PGID=$(ps -o pgid= $PROPID | grep -o '[0-9]*')
echo Groupd pid: $PGID

# Find other Processes that are part of group
A="$(ps -e -o pgid,pid= | grep [0-9])"
IFS=$'\n'
for i in $A; do
    GROUP_ID=$(printf "$i" | awk -F ' ' '{print $1}')
    PID=$(printf "$i" | awk '{print $2}')
    if [ "$GROUP_ID" = "$PGID" ]; then
        to_delete+=($PID)
    fi
done
unset IFS

# Remove protected PIDS from delete list
for del in ${PROPID[@]}; do
    to_delete=("${to_delete[@]/$del}")
done

# Kill processes
if [ ${#to_delete[@]} -eq 0 ]; then
    echo Stopping processes: ${to_delete[@]}
    sudo kill ${to_delete[@]}
fi
