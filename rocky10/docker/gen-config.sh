#!/bin/bash
# Helper script to generate config files from templates
# Uses environment variables or defaults

PORT="${PORT:-2222}"
NETWORK="${NETWORK:-10.0.10}"
PREFIX="${PREFIX:-lci}"
COMPUTE_MEMORY="${COMPUTE_MEMORY:-2g}"

echo "Generating with: PORT=$PORT, NETWORK=$NETWORK, PREFIX=$PREFIX, COMPUTE_MEMORY=$COMPUTE_MEMORY"

# Generate docker-compose.yml
sed \
    -e "s|{{PORT}}|$PORT|g" \
    -e "s|{{NETWORK}}|$NETWORK|g" \
    -e "s|{{PREFIX}}|$PREFIX|g" \
    -e "s|{{COMPUTE_MEMORY}}|$COMPUTE_MEMORY|g" \
    docker-compose.yml.template > docker-compose.yml

# Generate cluster-config.yml  
sed \
    -e "s|{{PORT}}|$PORT|g" \
    -e "s|{{NETWORK}}|$NETWORK|g" \
    -e "s|{{PREFIX}}|$PREFIX|g" \
    -e "s|{{COMPUTE_MEMORY}}|$COMPUTE_MEMORY|g" \
    cluster-config.yml.template > cluster-config.yml

echo "Generated: docker-compose.yml, cluster-config.yml"
