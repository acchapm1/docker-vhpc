# Rocky Linux 9.7 HPC Cluster

Virtual HPC cluster using Rocky Linux 9.7 with Docker containerization.

## Features

- **Rocky Linux 9.7** base image across all nodes
- **Multi-stage Docker builds** for optimized image sizes
- **Scalable architecture** - 1 head node, up to 10 compute nodes, up to 3
  storage nodes
- **Centralized configuration** - All variables in Justfile (PORT, NETWORK,
  PREFIX, CLUSTER_NUM, etc.)
- **LCI lab naming** - `{PREFIX}-{role}-{CC}-{N}`, e.g. asu-head-01-1,
  asu-compute-01-1, asu-storage-01-1
- **Pre-installed tools** - tmux, neovim, vim, wget on all nodes

## Quick Start

```bash
cd hpc-rocky9

# Show all commands
just --list

# Build and start cluster
just setup

# SSH into head node
just ssh rocky
```

## Documentation

- [HOWTO.md](HOWTO.md) - Quick start guide and troubleshooting
- [CONFIGURATION.md](CONFIGURATION.md) - Centralized configuration guide
- [NAMING.md](NAMING.md) - Container naming conventions
- [commands](commands) - Quick command reference

## Cluster Architecture

Names follow the LCI convention `{PREFIX}-{role}-{CC}-{N}` where `CC` is the
per-student cluster number. The hostname matches the container name exactly.
Defaults below use prefix `asu` and cluster number `01`.

| Node      | Container Name = Hostname | IP Address |
| --------- | ------------------------- | ---------- |
| Head      | asu-head-01-1             | 10.0.10.2  |
| Compute 1 | asu-compute-01-1          | 10.0.10.3  |
| Compute 2 | asu-compute-01-2          | 10.0.10.4  |
| Storage 1 | asu-storage-01-1          | 10.0.10.5  |

See [NAMING.md](NAMING.md) for how to set your cluster number and prefix.

## Prerequisites

- Docker and Docker Compose
- Just (task runner)
- Ansible 2.14+ (optional)

## License

MIT License
