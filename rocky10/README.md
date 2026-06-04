# Rocky Linux 10.1 HPC Cluster

Virtual HPC cluster using Rocky Linux 10.1 with Docker containerization.

## Features

- **Rocky Linux 10.1** base image across all nodes
- **`just inter` template** - one command stands up a 4-storage-node cluster with
  raw drives for parallel-filesystem labs
- **Multi-stage Docker builds** for optimized image sizes
- **Scalable architecture** - 1 head node, up to 10 compute nodes, up to 10
  storage nodes
- **Centralized configuration** - All variables in Justfile (PORT, NETWORK,
  PREFIX, CLUSTER_NUM, etc.)
- **LCI lab naming** - `{PREFIX}-{role}-{CC}-{N}`, e.g. lci-head-01-1,
  lci-compute-01-1, lci-storage-01-1
- **Pre-installed tools** - tmux, neovim, vim, wget on all nodes

## Templates

> **Note:** Rocky 10 ships the **`just inter`** template only. The **`just
> intro`** (shared NFS `/scratch`) template is **not available on Rocky 10** —
> `nfs-ganesha` is not packaged for EL10. Use the [`rocky9/`](../rocky9/) variant
> for the NFS-scratch workflow. See [INTRO.md](INTRO.md) for the full
> explanation and workarounds.

### `just inter` — raw drives for parallel filesystems

1 head + 2 compute + **4 storage**. Each storage node is bare (no NFS) and
exposes two **raw, unformatted 5g block devices** — `/dev/vdb` and `/dev/vdc` —
backed by loopback images, for hands-on parallel-filesystem labs (BeeGFS,
Lustre, Ceph). You format and configure them yourself.

```bash
cd rocky10
just inter

# Each storage node (lci-storage-01-1 .. -4) has raw vdb/vdc:
docker exec lci-storage-01-1 lsblk
docker exec lci-storage-01-1 blkid /dev/vdb        # empty -> raw, no filesystem

# Format it yourself (the drives ship raw):
docker exec lci-storage-01-1 mkfs.xfs /dev/vdb     # BeeGFS/Lustre OSD path
docker exec lci-storage-01-1 pvcreate /dev/vdc     # LVM / Ceph path
```

The drives and their data persist across `docker restart`.

## Quick Start

```bash
cd rocky10

# Show all commands
just --list

# Inter template (raw PFS drives) — one command, fully provisioned:
just inter

# Or the base cluster (1 head, 2 compute, 1 storage):
just setup

# SSH into the head node (rocky user, password: Sp@rky26)
just ssh rocky

# Tear it down
just down
```

## Documentation

- [INTRO.md](INTRO.md) - why `just intro` (NFS /scratch) is rocky9-only, plus
  workarounds; and `just inter` usage on Rocky 10
- [HOWTO.md](HOWTO.md) - Quick start guide and troubleshooting
- [CONFIGURATION.md](CONFIGURATION.md) - Centralized configuration guide
- [NAMING.md](NAMING.md) - Container naming conventions
- [commands](commands) - Quick command reference

## Cluster Architecture

Names follow the LCI convention `{PREFIX}-{role}-{CC}-{N}` where `CC` is the
per-student cluster number. The hostname matches the container name exactly.
Defaults below use prefix `lci` and cluster number `01`.

| Node      | Container Name = Hostname | IP Address |
| --------- | ------------------------- | ---------- |
| Head      | lci-head-01-1             | 10.0.10.2  |
| Compute 1 | lci-compute-01-1          | 10.0.10.3  |
| Compute 2 | lci-compute-01-2          | 10.0.10.4  |
| Storage 1 | lci-storage-01-1          | 10.0.10.5  |

Under `just inter`, storage nodes 2–4 are `lci-storage-01-2` (10.0.10.240), `-3`
(.241), and `-4` (.242). See [NAMING.md](NAMING.md) for how to set your cluster
number and prefix.

## Prerequisites

- Docker and Docker Compose
- Just (task runner): `brew install just`
- An SSH key pair (`~/.ssh/id_*`) for cluster access — see [HOWTO.md](HOWTO.md).

(No uv/Ansible needed on Rocky 10 — that's only used by the rocky9 Intro
template.)

## License

MIT License
