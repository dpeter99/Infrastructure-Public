#!/bin/bash

if [ -z "${GITHUB_TOKEN}" ]; then
  echo "Please set the GITHUB_TOKEN environment variable to a GitHub personal access token with repo permissions."
  exit 1
fi

flux bootstrap github \
  --token-auth \
  --owner=dpeter99 \
  --repository=Aperture-Infra \
  --branch=cluster-2 \
  --path=clusters/aper_cluster \
  --personal
