# Virtual HPC Cluster

A collection of Docker-based virtual HPC (High Performance Computing) clusters
for testing, development, and learning purposes. Each cluster variant provides a
multi-node environment with head, compute, and storage nodes.

## What is vHPC?

vHPC (Virtual HPC) creates a complete HPC cluster environment using Docker
containers. It simulates a real HPC environment with:

- **Head Node** - Login/management node with SSH access
- **Compute Nodes** - Scalable processing workers (1-10 nodes)
- **Storage Nodes** - Shared NFS storage for distributed data

This allows you to test HPC workflows, develop parallel applications, and learn
cluster administration without needing physical hardware.

## Features

- **Multi-stage Docker builds** for optimized image sizes
- **Scalable architecture** - Easily add/remove compute nodes
- **Centralized configuration** - All settings in a single Justfile
- **Consistent naming** - Predictable container and hostname patterns
- **SSH key management** - Passwordless access between nodes
- **Shared storage** - NFS mounts across all nodes
- **Pre-installed tools** - tmux, neovim, vim, wget on all nodes

## Available Versions

Choose your preferred Rocky Linux version:

| Version              | Directory              | Description                         |
| -------------------- | ---------------------- | ----------------------------------- |
| **Rocky Linux 9.7**  | [`rocky9/`](rocky9/)   | Stable, well-tested HPC environment |
| **Rocky Linux 10.1** | [`rocky10/`](rocky10/) | Latest version with newer packages  |

Each version directory contains its own:

- Complete setup instructions
- Docker configurations
- Ansible playbooks
- Documentation (HOWTO.md, CONFIGURATION.md, NAMING.md)

## Prerequisites

- **Docker** and Docker Compose
- **Just** task runner ([installation](https://github.com/casey/just))
- **Ansible** 2.14+ (optional, for automation)

## Quick Start

1. Navigate to your preferred version:

   ```bash
   cd rocky9    # or cd rocky10
   ```

2. Show all available commands:

   ```bash
   just --list
   ```

3. Build and start the cluster:

   ```bash
   just setup
   ```

4. SSH into the head node:
   ```bash
   just ssh rocky
   ```

## Project Structure

```
.
├── rocky9/          # Rocky Linux 9.7 HPC cluster
│   ├── README.md
│   ├── HOWTO.md
│   ├── CONFIGURATION.md
│   ├── NAMING.md
│   ├── Justfile
│   ├── docker/
│   └── ansible/
├── rocky10/         # Rocky Linux 10.1 HPC cluster
│   ├── README.md
│   ├── HOWTO.md
│   ├── CONFIGURATION.md
│   ├── NAMING.md
│   ├── Justfile
│   ├── docker/
│   └── ansible/
└── AGENTS.md        # Guidelines for AI contributors
```

## Adding New Versions

This repository is designed to accommodate additional vHPC versions. To add a
new variant:

1. Create a new directory (e.g., `rocky11/`)
2. Follow the structure from existing versions
3. Update this README to include the new version

## License

MIT License
