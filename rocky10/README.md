# Rocky Linux 10.1 HPC Cluster

Virtual HPC cluster using Rocky Linux 10.1 with Docker containerization.

## Features

- **Rocky Linux 10.1** on the head and compute nodes (the `just intro` storage
  node runs Rocky 9.7 — see the note under Templates)
- **One-command templates** - `just intro` and `just inter` stand up a fully
  configured, ready-to-use cluster in a single step
- **Multi-stage Docker builds** for optimized image sizes
- **Scalable architecture** - 1 head node, up to 10 compute nodes, up to 10
  storage nodes
- **Centralized configuration** - All variables in Justfile (PORT, NETWORK,
  PREFIX, CLUSTER_NUM, etc.)
- **LCI lab naming** - `{PREFIX}-{role}-{CC}-{N}`, e.g. lci-head-01-1,
  lci-compute-01-1, lci-storage-01-1
- **Pre-installed tools** - tmux, neovim, vim, wget on all nodes

## Templates

Two predefined cluster templates cover the common lab scenarios. Each is a
single command that does everything — generate config, build, start, wire
passwordless SSH, provision storage, and print status.

### `just intro` — shared NFS `/scratch`

1 head + 2 compute + 1 storage. The storage node serves its `/export` over NFSv4
(userspace nfs-ganesha), auto-mounted as **`/scratch`** on the head and both
compute nodes. The mount is persistent — it re-mounts after `docker restart`.

```bash
cd rocky10
just intro

# Verify the shared scratch (write on one node, read on another):
docker exec lci-head-01-1     bash -lc 'echo hello > /scratch/test.txt'
docker exec lci-compute-01-1  cat /scratch/test.txt   # -> hello
```

> **Note — storage node runs Rocky 9.7 (revisit later).** `just intro` needs a
> userspace NFS server (nfs-ganesha), and the EL10 build (ganesha 9) is not
> stable in this container setup. So the storage node image is pinned to
> `rockylinux:9.7` (ganesha 5, proven) while head/compute stay Rocky 10.1 — a
> harmless mixed-OS setup. Making the storage node fully Rocky 10 with native
> ganesha 9 is deferred; see [INTRO.md](INTRO.md) for what's known and the
> remaining work.

The `/scratch` mount is provisioned with Ansible from a self-contained **uv**
environment — see Prerequisites.

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

# Predefined templates (recommended) — one command, fully provisioned:
just intro      # 1 head, 2 compute, 1 storage + shared NFS /scratch
just inter      # 1 head, 2 compute, 4 storage with raw vdb/vdc drives (PFS labs)

# SSH into the head node (rocky user, password: Sp@rky26)
just ssh rocky

# Tear it down
just down
```

## Documentation

- [INTRO.md](INTRO.md) - why the `just intro` storage node runs Rocky 9.7, and
  the path to native ganesha 9 on Rocky 10 (future work)
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
- **uv** (for the `just intro` Ansible step): https://docs.astral.sh/uv/ —
  `just intro` provisions a pinned Python 3.12 Ansible environment automatically
  (`just ansible-setup`); no system Ansible required. (`just inter` does not need
  uv.)
- An SSH key pair (`~/.ssh/id_*`) for cluster access — see [HOWTO.md](HOWTO.md).

## License

MIT License
