# Rocky Linux 9.7 HPC Cluster

Virtual HPC cluster using Rocky Linux 9.7 with Docker containerization.

## Features

- **Rocky Linux 9.7** base image across all nodes
- **Multi-stage Docker builds** for optimized image sizes
- **One-command templates** - `just intro` and `just inter` stand up a fully
  configured, ready-to-use cluster in a single step
- **Scalable architecture** - 1 head node, up to 10 compute nodes, up to 10
  storage nodes
- **Centralized configuration** - All variables in Justfile (PORT, NETWORK,
  PREFIX, CLUSTER_NUM, etc.)
- **LCI lab naming** - `{PREFIX}-{role}-{CC}-{N}`, e.g. lci-head-01-1,
  lci-compute-01-1, lci-storage-01-1
- **Pre-installed tools** - tmux, neovim, vim, wget on all nodes

## Quick Start

```bash
cd rocky9

# Show all commands
just --list

# Predefined templates (recommended) — one command, fully provisioned:
just intro      # 1 head, 2 compute, 1 storage + shared NFS /scratch
just inter      # 1 head, 2 compute, 4 storage with raw vdb/vdc drives (PFS labs)

# SSH into the head node (rocky user, password: Sp@rky26)
just ssh rocky

# Tear it down
just down
```

Prefer building piece by piece? `just setup` runs config + build + up +
copy-ssh-key + status for the base topology.

## Templates

Two predefined cluster templates cover the common lab scenarios. Each is a
single command that does everything — generate config, build, start, wire
passwordless SSH, provision storage, and print status.

### `just intro` — shared NFS scratch

1 head + 2 compute + 1 storage. The storage node serves its `/export` over NFSv4
(userspace nfs-ganesha), and it is auto-mounted as **`/scratch`** on the head
and both compute nodes. The mount is persistent — it re-mounts after
`docker restart`.

```bash
just intro

# Verify the shared scratch (write on one node, read on another):
just exec                                          # shell into the head
#   on head:    echo hello > /scratch/test.txt
docker exec lci-compute-01-1 cat /scratch/test.txt # -> hello
```

The `/scratch` mount is provisioned with Ansible (run automatically by
`just intro`). Ansible runs from a self-contained **uv** environment — see
Prerequisites.

### `just inter` — raw drives for parallel filesystems

1 head + 2 compute + **4 storage**. Each storage node is bare (no NFS) and
exposes two **raw, unformatted 5g block devices** — `/dev/vdb` and `/dev/vdc` —
backed by loopback images. These are for hands-on parallel-filesystem labs
(BeeGFS, Lustre, Ceph): students format and configure them.

```bash
just inter

# Each storage node (lci-storage-01-1 .. -4) has raw vdb/vdc:
docker exec lci-storage-01-1 lsblk
docker exec lci-storage-01-1 blkid /dev/vdb        # empty -> raw, no filesystem

# Format it yourself (the drives ship raw):
docker exec lci-storage-01-1 mkfs.xfs /dev/vdb     # BeeGFS/Lustre OSD path
docker exec lci-storage-01-1 pvcreate /dev/vdc     # LVM / Ceph path
```

The drives and their data persist across `docker restart`.

## Documentation

- [HOWTO.md](HOWTO.md) - Quick start guide, templates, and troubleshooting
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
- **uv** (for the `just intro` Ansible step): https://docs.astral.sh/uv/ —
  `just intro` provisions a pinned Python 3.12 Ansible environment automatically
  (`just ansible-setup`); no system Ansible required.
- An SSH key pair (`~/.ssh/id_*`) for cluster access — see [HOWTO.md](HOWTO.md).

## License

MIT License
