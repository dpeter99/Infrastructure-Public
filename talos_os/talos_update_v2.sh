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
APPLY_SCRIPT=$(talhelper gencommand apply)

if [ $? -eq 1 ]; then
  echo "  [] Failed to generate the apply script."
  exit 1
fi

echo "  [] Running the apply script..."

node_regex="--nodes=([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)"

while IFS= read -r line; do
    echo "$line"
    eval "$line"
    sleep 20
    if [[ $line =~ $node_regex ]];
    then
      name="${BASH_REMATCH[1]}"
      echo "  [] Waiting for the node (${name}) to come back online..."

      status=$(talosctl get nodestatus --nodes ${name} --output json | jq .spec.nodeReady)
      until [[ $status = 'true' ]]
      do
        echo "status: ${status}"
        sleep 5
        status=$(talosctl get nodestatus --nodes ${name} --output json | jq .spec.nodeReady)
        echo "..."
      done
      echo "  [] Node status: ${status}"

    fi
done <<< "$APPLY_SCRIPT"
