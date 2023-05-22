#!/usr/bin/env bash
#set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately

echo "Starting instance"


cd ..

## Connection to Azure with container identity
if [ -n "$SUBSCRIPTION_ID" ]; then ## Executed locally
    az login
    az account set --subscription $SUBSCRIPTION_ID
 else ## Executed on Container Apps
    python -u -m python_launcher
fi

