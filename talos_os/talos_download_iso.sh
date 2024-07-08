#!/usr/bin/env sh
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

echo "[] Downloading Talos ISO..."

URL=$(talhelper genurl iso --secure-boot)
wget $URL -O talos.iso