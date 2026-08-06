#!/usr/bin/env bash
set -euo pipefail

# New repositories
git config --global init.defaultBranch main

# Multi-machine synchronization
git config --global pull.rebase true
git config --global rebase.autoStash true
git config --global fetch.prune true

# Make first push of a new branch set its upstream automatically
git config --global push.autoSetupRemote true
git config --global push.default simple

# Make first push of a new branch set its upstream automatically
git config --global push.autoSetupRemote true
git config --global push.default simple

# ID
git config --global user.name "Joe Battistello"
git config --global user.email "joebattist@hotmail.com"

# Show off
git config --global --list --show-origin
