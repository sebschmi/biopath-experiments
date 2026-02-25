#!/usr/bin/env bash

set +e

echo "Checking for running snakemake"
ps ux | grep -F "bin/snakemake " | grep -v grep
if [ "${PIPESTATUS[2]}" -ne "0" ]; then
    echo "No snakemake found"
else
    echo "Snakemake is already running!"
    exit 1
fi

set -e

HOSTNAME=$(hostname)
LOG="current.log"
rm -f "$LOG"

echo "Logging to $LOG"
echo "Arguments: $@" >> "$LOG"
echo "Start time: $(date +"%FT%R:%S")" >> "$LOG"

if [[ $HOSTNAME == "dx3"* ]]; then
    echo "Running on dx3, using profile dx3"
    nohup snakemake --profile profiles/dx3 "$@" >> $LOG 2>&1 &
else
    echo "Running on unknown host $HOSTNAME, using default profile"
    nohup snakemake "$@" >> $LOG 2>&1 &
fi