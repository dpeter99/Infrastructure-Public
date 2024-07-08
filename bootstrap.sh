#!/usr/bin/env sh
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

source ./common.sh

echo "Bootstrapping Aperture Cluster..."


echo "  [] Installing Cilium..."
source ./cilium_install.sh

wait 100

until [ $(talosctl get nodestatus --talosconfig talos_os/clusterconfig/talosconfig --output json | jq '.spec.nodeReady') = true ] ; do
echo "Waiting for nodes to be ready..."
sleep 10
done

echo "  [] Installing Flux..."
source ./bootstrap_flux.sh