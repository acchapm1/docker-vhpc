# Centralized Configuration Guide

This HPC cluster uses centralized configuration variables in the Justfile.

## Configuration Variables (Edit at the top of the Justfile)

### Core Variables

```bash
PORT := "2222"           # SSH port for external access
NETWORK := "10.0.10"     # Docker network subnet (first 3 octets)
PREFIX := "asu"          # Container name prefix
CLUSTER_NUM := "01"      # Virtual cluster number (per student, zero-padded)
```

Node names follow the LCI lab convention `{PREFIX}-{role}-{CC}-{N}`, where `CC`
is `CLUSTER_NUM` and `N` is the per-role instance number. See
[NAMING.md](NAMING.md) for the full breakdown.

### Scalability Variables

```bash
COMPUTE_NODES := "2"     # Number of compute nodes (1-10)
STORAGE_NODES := "1"     # Number of storage nodes (1-3 for distributed storage)
COMPUTE_MEMORY := "2g"   # Memory limit per compute node
STORAGE_SIZE := "10g"    # Size of storage backing file
ENABLE_MONITORING := "false"  # Include prometheus/grafana (future feature)
```

## How It Works

1. **Edit variables** at the top of the Justfile
2. **Run**: `just generate-config` (automatically called by build/up/setup)
3. **Generated files**:
   - `docker/docker-compose.yml` - Main compose file with your settings
   - `docker/cluster-config.yml` - Additional node configurations

## Quick Examples

### Example 1: Change SSH Port

```bash
# Edit the PORT variable:
PORT := "2244"

# Then rebuild:
just setup
```

### Example 2: Different Network

```bash
# Edit the NETWORK variable:
NETWORK := "172.29.10"

# Then rebuild:
just setup
```

### Example 3: More Compute Nodes

```bash
# Edit the COMPUTE_NODES variable:
COMPUTE_NODES := "5"

# Or use command line:
just up-with 5

# Then rebuild:
just setup
```

### Example 4: More Memory for Compute Nodes

```bash
# Edit the COMPUTE_MEMORY variable:
COMPUTE_MEMORY := "4g"

# Then rebuild:
just setup
```

### Example 5: Set Your Cluster Number

```bash
# Edit the CLUSTER_NUM variable to your assigned number:
CLUSTER_NUM := "04"

# Node names will be (default prefix asu):
# asu-head-04-1
# asu-compute-04-1
# asu-compute-04-2
# asu-storage-04-1

# Then rebuild:
just setup
```

### Example 6: Custom Prefix

```bash
# Edit the PREFIX variable:
PREFIX := "lci"

# With CLUSTER_NUM := "02", container names will be:
# lci-head-02-1
# lci-compute-02-1
# lci-compute-02-2
# lci-storage-02-1

# Then rebuild:
just setup
```

## Variable Propagation

All variables automatically propagate to:

- ✅ Container and host names (PREFIX, CLUSTER_NUM)
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

storage-CC-2..M come up bare (no NFS), ready for you to install BeeGFS or Ceph
on `/data`. See [HOWTO.md](HOWTO.md) for the layout.

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
