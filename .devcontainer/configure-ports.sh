#!/bin/bash

echo "Configuring ports..."

gh codespace ports visibility 3000:public -c $CODESPACE_NAME
gh codespace ports visibility 9650:public -c $CODESPACE_NAME

echo "Ports configuration completed!"
