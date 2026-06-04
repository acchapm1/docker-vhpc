# Rocky Linux 10.1 HPC Cluster - Quick Start Guide

Virtual HPC cluster using Rocky Linux 10.1 with Docker.

Includes tmux, neovim/nvim, vim, and wget.

## Prerequisites

- Docker and Docker Compose
- Just (task runner): `brew install just` or see
  [Just](https://github.com/casey/just)
- SSH key pair for cluster access (see below)

> **Rocky 10 note:** this variant ships the **`just inter`** template only. The
> **`just intro`** (NFS `/scratch`) template is **not available on Rocky 10** —
> `nfs-ganesha` is not packaged for EL10. Use the [`rocky9/`](../rocky9/) variant
> for the shared-scratch workflow. See [INTRO.md](INTRO.md) for details.

## SSH Key Setup

Before using the cluster, generate an SSH key pair on your host machine. The
`just copy-ssh-key` command will copy this key to the containers.

### Linux

```bash
# Generate ED25519 key (recommended)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "your_email@example.com"

# Or generate RSA key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "your_email@example.com"

# Start SSH agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### macOS

```bash
# Generate ED25519 key (recommended)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "your_email@example.com"

# Or generate RSA key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "your_email@example.com"

# Start SSH agent and add key (macOS 10.12.2+)
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# For older macOS versions
ssh-add -K ~/.ssh/id_ed25519
```

### Windows (WSL - Windows Subsystem for Linux)

Open WSL terminal (Ubuntu, Debian, etc.):

```bash
# Generate ED25519 key (recommended)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "your_email@example.com"

# Or generate RSA key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "your_email@example.com"

# Start SSH agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Ensure proper permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### Using a Custom SSH Key

If you prefer a different key name or location:

```bash
# Generate key with custom name
ssh-keygen -t ed25519 -f ~/.ssh/id_vhpc -C "vhpc_cluster"

# Use custom key with copy-ssh-key
PUBKEY=~/.ssh/id_vhpc.pub just copy-ssh-key

# SSH with custom key
ssh -i ~/.ssh/id_vhpc rocky@localhost -p 2222
```

### Verifying SSH Key Setup

```bash
# Check that your key exists
ls -la ~/.ssh/id_*.pub

# Test key (after cluster is running)
ssh -i ~/.ssh/id_ed25519 rocky@localhost -p 2222 'hostname'
```

## Quick Start

```bash
# Show all available commands
just --list

# Build, start, and setup SSH keys (base topology)
just setup

# Or run individually:
just build && just up && just copy-ssh-key && just status
```

## Predefined Templates

Rocky 10 ships one single-command template, **`just inter`**. (The NFS
`/scratch` **`just intro`** template is rocky9-only — `nfs-ganesha` is not
packaged for EL10; see [INTRO.md](INTRO.md).) The recipe does everything:
generate config → build → start → wire passwordless SSH → provision storage →
show status.

### `just inter` — raw drives for parallel filesystems

```bash
just inter
```

Brings up **1 head + 2 compute + 4 storage**. Each storage node is bare (no NFS)
and exposes two **raw, unformatted 5g block devices**, `/dev/vdb` and
`/dev/vdc`, backed by loopback images. They are intended for hands-on
parallel-filesystem labs (BeeGFS, Lustre, Ceph) — you format and configure them
yourself. Stable device names (`/dev/vdb`/`/dev/vdc`) are guaranteed regardless
of which host loop device each lands on. Drives and their data persist across
`docker restart`.

```bash
# Inspect the raw drives on any storage node (lci-storage-01-1 .. -4):
docker exec lci-storage-01-1 lsblk
docker exec lci-storage-01-1 ls -l /dev/vdb /dev/vdc
docker exec lci-storage-01-1 blkid /dev/vdb        # empty output => raw

# Format them yourself — they ship raw:
docker exec lci-storage-01-1 mkfs.xfs /dev/vdb     # XFS (BeeGFS/Lustre OSD)
docker exec lci-storage-01-1 pvcreate /dev/vdc     # LVM PV (LVM/Ceph)
```

No `/scratch`/NFS mount is provisioned — the storage nodes are PFS targets, not
a shared scratch source.

## Customizing Cluster Size

### Default Configuration

By default, each cluster includes:

- 1 head node (login/management node)
- 2 compute nodes (lci-compute-01-1, lci-compute-01-2)
- 1 storage node (NFS server, lci-storage-01-1)

Node names follow the LCI convention `{PREFIX}-{role}-{CC}-{N}`, where `CC` is
your assigned cluster number. The hostname matches the container name exactly.
Set the prefix via `PREFIX` and your cluster number via `CLUSTER_NUM` in the
Justfile (see [NAMING.md](NAMING.md)). Examples below use the default prefix
`lci` and cluster number `01`.

### Option 1: Use Just Helper (Easiest)

Start the cluster with a custom number of compute nodes:

```bash
just up-with 4   # Starts with 4 compute nodes (compute-01-1 .. compute-01-4)
```

This automatically generates a `cluster-config.yml` file and starts the cluster
with your desired node count (1-10 nodes supported).

### Option 2: Inspect the generated overlay

`just up-with` calls `just init-cluster N [M]` under the hood, which writes
`docker/cluster-config.yml` and is then merged with the base
`docker-compose.yml`. To inspect what will be started without launching:

```bash
just init-cluster 5 3
docker-compose -f docker/docker-compose.yml -f docker/cluster-config.yml config
```

`cluster-config.yml` is a generated file — do not edit it by hand. Re-run
`init-cluster` (or `up-with`) to regenerate.

**Available IP ranges (cluster number `01`):**

- 10.0.10.2-10.0.10.254 (head=.2, compute-01-1..2=.3-.4, storage-01-1=.5,
  compute-01-3..10=.6-.13, storage-01-2..10=.240-.248)

### Adding Storage Nodes

Pass a second argument to `up-with` to scale the storage tier:

```bash
just up-with 3 3    # 3 compute nodes + 3 storage nodes
```

storage-01-1 keeps running an NFS server (the default cluster behavior).
storage-01-2..M come up with `DISABLE_NFS_AUTOSTART=1` — sshd is reachable,
`/data` is an empty scratch volume, and no NFS server is started. These bare
nodes are intended for installing a distributed filesystem (BeeGFS, Ceph, etc.)
under your own configuration.

storage-01-2..M use the reserved IP range `NETWORK.240-249` (see
[NAMING.md](NAMING.md)) so they never collide with compute nodes.

### Maximum Node Count

- **Compute nodes:** Up to 10 (compute-CC-1..compute-CC-10, IPs `NETWORK.3-13`)
- **Storage nodes:** Up to 10 (storage-CC-1 at `NETWORK.5`, storage-CC-2..10 at
  `NETWORK.240-248`)
- **Head nodes:** 1 (cannot be scaled, contains management functions)

### Checking Cluster Status

View running nodes:

```bash
just status
```

List all containers (default prefix `lci`):

```bash
docker ps --filter "name=lci-"
```

### Troubleshooting Scale Issues

**Problem: IP address conflict**

- Ensure each node has a unique IP address
- Use the `hostname -I` command inside containers to verify

**Problem: Container name collision**

- Each `container_name` must be unique
- Format: `{PREFIX}-{role}-{CC}-{N}` (e.g., lci-compute-01-3, lci-storage-01-2)

**Problem: Service not starting**

- Check logs: `docker-compose logs compute3`
- Verify dependencies: All compute nodes depend on head node

## Cluster Architecture

Defaults below use prefix `lci` and cluster number `01`.

| Node     | Container Name = Hostname | IP Address | SSH Port | Role         |
| -------- | ------------------------- | ---------- | -------- | ------------ |
| head     | lci-head-01-1             | 10.0.10.2  | 2222     | Login node   |
| compute1 | lci-compute-01-1          | 10.0.10.3  | -        | Compute node |
| compute2 | lci-compute-01-2          | 10.0.10.4  | -        | Compute node |
| storage  | lci-storage-01-1          | 10.0.10.5  | -        | NFS/Storage  |

Under `just inter`, three more storage nodes are added: `lci-storage-01-2`
(10.0.10.240), `lci-storage-01-3` (10.0.10.241), `lci-storage-01-4`
(10.0.10.242).

### Storage Node Access

The storage node has SSH access from the head node for testing storage solutions
(BeeGFS, ZFS, etc.):

```bash
# After SSHing to head node as rocky and elevating to root
ssh root@lci-compute-01-1
ssh root@lci-compute-01-2
ssh root@lci-storage-01-1
```

The `rocky` user cannot SSH between nodes - only `root` has inter-node access.

## Common Commands

```bash
# List running containers
docker ps

# View container logs
docker logs lci-head-01-1

# Execute command in container
docker exec -it lci-head-01-1 bash

# Stop containers
just down

# Clean up everything (images, volumes, networks)
just clean
```

## Troubleshooting

### SSH connection refused

- Ensure containers are running: `docker ps`
- Check if SSH is running: `docker logs lci-head-01-1`
- Re-run SSH key setup: `just copy-ssh-key`

### Permission denied

- Verify you're using the correct user/password
- For rocky user, use: `ssh rocky@localhost -p 2222`
- For root user, use: `ssh root@localhost -p 2222`

### Clear command not found

- The `ncurses` package is installed for the `clear` command
- If missing, rebuild: `just build`

### Inter-node SSH fails

- Only `root` can SSH between nodes
- SSH to head as root first, then SSH to compute/storage nodes

### sudo command fails

- Ensure sudo is installed in the runtime stage (fixed in current Dockerfiles)
- If `libsudo_util.so.0` error occurs, rebuild: `just build`

## Persistence and Temporary Nature

These virtual clusters are **ephemeral** - changes do not persist across
rebuilds:

| Action                  | Configs (/etc) | Data (/var) | Installed Software (/usr) |
| ----------------------- | -------------- | ----------- | ------------------------- |
| Container restart       | Preserved      | Preserved   | Preserved                 |
| `just down` / `just up` | **Lost**       | **Lost**    | **Lost**                  |
| Image rebuild           | **Lost**       | **Lost**    | **Lost**                  |

### For Persistent Changes

To make changes permanent, modify the Dockerfiles and rebuild:

1. **Add software**: Edit the `RUN dnf -y install` line in the Dockerfile
2. **Add config files**: Add `COPY` commands for your config files
3. **Run setup scripts**: Add `RUN` commands or modify `start-*.sh` scripts
4. **Rebuild**: `just build && just up && just copy-ssh-key`

### For Development/Testing

If you need to test changes before baking them into images:

```bash
# Install software temporarily (lost on container recreation)
docker exec -it lci-head-01-1 dnf -y install <package>

# Make config changes (persists until volume is removed)
docker exec -it lci-head-01-1 vi /etc/some/config
```

For reproducible configuration, bake changes into the Dockerfiles and rebuild
(`just build && just up`). The rocky9 variant additionally offers an Ansible
workflow; rocky10 does not ship one.
