#!/usr/bin/env sh
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

source ../common.sh

echo "[] Bootstrapping the Talos cluster..."

echo "  [] Generating the Talos configuration..."
talhelper genconfig

if [ $? -eq 1 ]; then
  echo "  [] Failed to generate the Talos configuration."
  exit 1
fi

mkdir -p _temp

echo "  [] Generating the apply script..."
talhelper gencommand apply --extra-flags "--insecure" > ./_temp/talos_apply.sh

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

sleep 10

echo "  [] Waiting for the Talos cluster to be ready..."
until talosctl --talosconfig clusterconfig/talosconfig get nodes 2> /dev/null | grep -q "Ready"

echo "  [] Generating the bootstrap script..."
talhelper gencommand bootstrap > ./_temp/talos_bootstrap.sh

echo "  [] Running the bootstrap script..."
chmod +x ./_temp/talos_bootstrap.sh

until ./_temp/talos_bootstrap.sh 2> /dev/null
do
  echo "Talos bootstrap failed, retrying in 20 seconds..."
  sleep 20
done

echo "[] Finished bootstrapping the Talos cluster."

echo "  [] Generating the kubeconfig..."
talosctl kubeconfig -e 10.1.2.1 -n 10.1.2.1 -f --talosconfig clusterconfig/talosconfig