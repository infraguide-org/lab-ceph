#!/usr/bin/env bash
# Source: https://github.com/infraguide-org/lab-ceph
# Copyright (c) 2026 infraguide.org, MIT License
#
# Lab specific part of the sandbox installation: fetches the lab configs,
# prepares the ssh config and creates the lab environment.
# Run as root after the nfgd.net/setup/sandbox script.
##############################################################################
# vars
NFGD_HOME="/infraguide/setup-sandbox"
REPO="infraguide-org/lab-ceph"
REF="main"
DIR="conf"
DEST="$DIR"

# the directory should be already created by nfgd.net/setup/sandbox script
cd "$NFGD_HOME"
source /etc/profile.d/*-lab.sh

##############################################################################
# Fetch the configs for the lab
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "https://codeload.github.com/${REPO}/tar.gz/${REF}" \
  | tar -xz -C "$tmp" --strip-components=1

if [ ! -d "${tmp}/${DIR}" ]
then
  echo "Directory '${DIR}' not found in ${REPO}@${REF}" >&2
  exit 1
fi

mkdir -p "$DEST"
cp -a "${tmp}/${DIR}"/* "$DEST"/

##############################################################################
# ssh config
./scripts/print-ssh-config  >> ~/.ssh/config

##############################################################################
# create environment

# vars
LAB_INFRA_NODES_GR1="dns|proxy|registry"
LAB_INFRA_NODES_GR2="deployment|recorder"

##############################################################################
# Infra nodes group1
print-create-env-commands  | grep -E "name +($LAB_INFRA_NODES_GR1)" | bash

echo ""
echo "Waiting for the first group to get prapared"; sleep 120
echo ""
##############################################################################
# Infra nodes group2
print-create-env-commands  | grep -E "name +($LAB_INFRA_NODES_GR2)" | bash

##############################################################################
# More nodes
print-create-env-commands  | grep -v -E "name +($LAB_INFRA_NODES_GR1|$LAB_INFRA_NODES_GR2)" | bash
