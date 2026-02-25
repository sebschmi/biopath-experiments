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

HOSTNAME = $(hostname)

if [[ $HOSTNAME == "dx3"* ]]; then
    echo "Running on dx3, using profile dx3"
    nohup snakemake --profile profiles/dx3 "$@" > current.log 2>&1 &
else
    echo "Running on unknown host $HOSTNAME, using default profile"
    nohup snakemake "$@" > current.log 2>&1 &
fi