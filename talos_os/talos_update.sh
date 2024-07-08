#!/usr/bin/env sh
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

source ../common.sh

echo "[] Updating the Talos cluster..."

echo "  [] Generating the Talos configuration..."
talhelper genconfig

if [ $? -eq 1 ]; then
  echo "  [] Failed to generate the Talos configuration."
  exit 1
fi

mkdir -p _temp


echo "  [] Generating the apply script..."
talhelper gencommand apply > ./_temp/talos_apply.sh

if [ $? -eq 1 ]; then
  echo "  [] Failed to generate the apply script."
  exit 1
fi

echo "  [] Running the apply script..."
chmod +x ./_temp/talos_apply.sh
source ./_temp/talos_apply.sh | indent
exit_status=${PIPESTATUS[0]}

if [ $exit_status -eq 1 ]; then
  echo "  [] Failed to apply the Talos cluster."
  exit 1
fi

echo "[] Finished updating the Talos cluster."

echo "  [] Generating the kubeconfig..."
talosctl kubeconfig --nodes 10.1.2.1 --endpoints 10.1.2.1 --talosconfig clusterconfig/talosconfig --force