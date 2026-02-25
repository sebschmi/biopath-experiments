#!/usr/bin/env bash

set +e

HOSTNAME = $(hostname)

if [[ $HOSTNAME == "dx3"* ]]; then
    echo "Running on dx3, using profile dx3"
    snakemake --profile profiles/dx3
else
    echo "Running on unknown host $HOSTNAME, using default profile"
    snakemake
fi