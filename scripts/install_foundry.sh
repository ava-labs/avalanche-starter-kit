#!/usr/bin/env bash
# Copyright (C) 2023, Ava Labs, Inc. All rights reserved.
# See the file LICENSE for licensing terms.

set -e

# The foundry install script uses XDG_CONFIG_HOME as the root of the install.
# This can vary for different environments, so it is set to $HOME for consistency.
export XDG_CONFIG_HOME=$HOME

# This installs from ava-labs fork of the foundry repo.
FOUNDRY_VERSION=v0.1.0
curl -L https://raw.githubusercontent.com/ava-labs/foundry/${FOUNDRY_VERSION}/foundryup/install > /tmp/foundry-install-script
# Set the foundry version in the install script
# Avoid using sed -i due to macos m1 incompatibility
sed "s/\/ava-labs\/foundry\/master\/foundryup/\/ava-labs\/foundry\/${FOUNDRY_VERSION}\/foundryup/g" /tmp/foundry-install-script
cat /tmp/foundry-install-script | bash

export PATH=$PATH:$HOME/.foundry/bin:$HOME/.foundry:$HOME/.cargo/bin
foundryup --version ${FOUNDRY_VERSION}