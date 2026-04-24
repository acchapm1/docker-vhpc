# Rocky Linux 9.7 HPC Cluster

Virtual HPC cluster using Rocky Linux 9.7 with Docker containerization.

## Features

- **Rocky Linux 9.7** base image across all nodes
- **Multi-stage Docker builds** for optimized image sizes
- **Scalable architecture** - 1 head node, up to 10 compute nodes, up to 3
  storage nodes
- **Centralized configuration** - All variables in Justfile (PORT, NETWORK,
  VARIANT, etc.)
- **Consistent naming** - lci-head-01, lci-compute-01, lci-storage-01
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

| Node      | Container Name | Hostname   | IP Address  |
| --------- | -------------- | ---------- | ----------- |
| Head      | lci-head-01    | head-01    | 172.29.10.2 |
| Compute 1 | lci-compute-01 | compute-01 | 172.29.10.3 |
| Compute 2 | lci-compute-02 | compute-02 | 172.29.10.4 |
| Storage   | lci-storage-01 | storage-01 | 172.29.10.5 |

## Prerequisites

- Docker and Docker Compose
- Just (task runner)
- Ansible 2.14+ (optional)

## License

MIT License
