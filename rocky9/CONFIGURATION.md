# Centralized Configuration Guide

This HPC cluster uses centralized configuration variables in the Justfile.

## Configuration Variables (Edit in Justfile, lines 6-15)

### Core Variables

```bash
PORT := "2222"           # SSH port for external access
NETWORK := "172.29.10"   # Docker network subnet (first 3 octets)
VARIANT := "lci"         # Container name prefix
```

### Scalability Variables

```bash
COMPUTE_NODES := "2"     # Number of compute nodes (1-10)
STORAGE_NODES := "1"     # Number of storage nodes (1-3 for distributed storage)
COMPUTE_MEMORY := "2g"   # Memory limit per compute node
STORAGE_SIZE := "10g"    # Size of storage backing file
ENABLE_MONITORING := "false"  # Include prometheus/grafana (future feature)
```

## How It Works

1. **Edit variables** in Justfile (lines 6-15)
2. **Run**: `just generate-config` (automatically called by build/up/setup)
3. **Generated files**:
   - `docker/docker-compose.yml` - Main compose file with your settings
   - `docker/cluster-config.yml` - Additional node configurations

## Quick Examples

### Example 1: Change SSH Port

```bash
# Edit Justfile line 6:
PORT := "2244"

# Then rebuild:
just setup
```

### Example 2: Different Network

```bash
# Edit Justfile line 7:
NETWORK := "10.0.10"

# Then rebuild:
just setup
```

### Example 3: More Compute Nodes

```bash
# Edit Justfile line 11:
COMPUTE_NODES := "5"

# Or use command line:
just up-with 5

# Then rebuild:
just setup
```

### Example 4: More Memory for Compute Nodes

```bash
# Edit Justfile line 13:
COMPUTE_MEMORY := "4g"

# Then rebuild:
just setup
```

### Example 5: Custom Naming

```bash
# Edit Justfile line 8:
VARIANT := "mycluster"

# Container names will be:
# mycluster-head-01
# mycluster-compute-01
# mycluster-compute-02
# mycluster-storage-01

# Then rebuild:
just setup
```

## Variable Propagation

All variables automatically propagate to:

- ✅ Container names (VARIANT)
- ✅ Network configuration (NETWORK)
- ✅ SSH port mapping (PORT)
- ✅ Memory limits (COMPUTE_MEMORY)
- ✅ IP addresses (NETWORK)
- ✅ Cluster scaling (COMPUTE_NODES, STORAGE_NODES)

## Testing Different Scenarios

### Performance Testing

```bash
# High-performance configuration
COMPUTE_NODES := "8"
COMPUTE_MEMORY := "8g"
STORAGE_SIZE := "50g"
```

### Development/Testing

```bash
# Lightweight configuration
COMPUTE_NODES := "1"
COMPUTE_MEMORY := "1g"
STORAGE_SIZE := "5g"
```

### Distributed Storage Testing

```bash
# Default storage count (used by `just up-with N` one-arg form)
STORAGE_NODES := "3"

# Or pass the count directly to up-with:
just up-with 3 3   # 3 compute + 3 storage nodes
```

storage-02..M come up bare (no NFS), ready for you to install BeeGFS or
Ceph on `/data`. See [HOWTO.md](HOWTO.md) for the layout.

## Commands

```bash
# Generate config files (auto-run by build/up/setup)
just generate-config

# Full setup with current config
just setup

# Scale cluster
just up-with 5

# View current configuration
just --list  # Shows all variables at top
```

## Files Modified by Configuration

- `Justfile` - Source of truth (edit here only)
- `docker/docker-compose.yml` - Generated from template
- `docker/cluster-config.yml` - Generated from template
- `docker/docker-compose.yml.template` - Template file
- `docker/cluster-config.yml.template` - Template file
- `docker/gen-config.sh` - Generation helper script

## Benefits

✅ **Single source of truth** - All config in one place (Justfile) ✅ **No
hardcoded values** - Everything uses variables ✅ **Easy to change** - Edit
Justfile, rebuild ✅ **Flexible testing** - Quick scenario changes ✅
**Consistent naming** - All containers follow pattern ✅ **Scalable** - Easy to
add/remove nodes
