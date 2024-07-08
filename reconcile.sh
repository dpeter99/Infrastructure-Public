#!/usr/bin/env sh

indent() {
  sed 's/\(.*\)/  \1/'
}

echo "Bootstrapping Aperture Cluster..."

source update.sh | indent