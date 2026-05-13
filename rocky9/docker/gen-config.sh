#!/bin/bash
# Helper script to generate config files from templates
# Uses environment variables or defaults

PORT="${PORT:-2222}"
NETWORK="${NETWORK:-172.29.10}"
PREFIX="${PREFIX:-lci}"
COMPUTE_MEMORY="${COMPUTE_MEMORY:-2g}"

echo "Generating with: PORT=$PORT, NETWORK=$NETWORK, PREFIX=$PREFIX, COMPUTE_MEMORY=$COMPUTE_MEMORY"

# Generate docker-compose.yml
# Note: cluster-config.yml is produced by `just init-cluster <N>` and is not
# rendered here — it's the scale-out overlay, not a static template.
sed \
    -e "s|{{PORT}}|$PORT|g" \
    -e "s|{{NETWORK}}|$NETWORK|g" \
    -e "s|{{PREFIX}}|$PREFIX|g" \
    -e "s|{{COMPUTE_MEMORY}}|$COMPUTE_MEMORY|g" \
    docker-compose.yml.template > docker-compose.yml

echo "Generated: docker-compose.yml"
