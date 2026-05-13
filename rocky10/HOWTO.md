# Rocky Linux 10.1 HPC Cluster - Quick Start Guide

Virtual HPC cluster using Rocky Linux 10.1 with Docker.

Includes tmux, neovim/nvim, vim, and wget.

## Prerequisites

- Docker and Docker Compose
- Just (task runner): `brew install just` or see
  [Just](https://github.com/casey/just)
- Ansible 2.14+ (optional, for configuration management)
- SSH key pair for cluster access

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

# Build, start, and setup SSH keys
just setup

# Or run individually:
just build && just up && just copy-ssh-key && just status
```

## Customizing Cluster Size

### Default Configuration

By default, each cluster includes:

- 1 head node (login/management node)
- 2 compute nodes (compute1, compute2)
- 1 storage node (NFS server)

### Option 1: Use Just Helper (Easiest)

Start the cluster with a custom number of compute nodes:

```bash
just up-with 4   # Starts with 4 compute nodes (compute1-4)
```

This automatically generates a `cluster-config.yml` file and starts the cluster
with your desired node count (1-10 nodes supported).

### Option 2: Inspect the generated overlay

`just up-with` calls `just init-cluster N [M]` under the hood, which
writes `docker/cluster-config.yml` and is then merged with the base
`docker-compose.yml`. To inspect what will be started without launching:

```bash
just init-cluster 5 3
docker-compose -f docker/docker-compose.yml -f docker/cluster-config.yml config
```

`cluster-config.yml` is a generated file — do not edit it by hand. Re-run
`init-cluster` (or `up-with`) to regenerate.

**Available IP ranges:**

- hpc-rocky10: 10.0.10.2-10.0.10.254 (head=.2, compute-01..02=.3-.4,
  storage-01=.5, compute-03..10=.6-.13, storage-02..10=.240-.248)

### Adding Storage Nodes

Pass a second argument to `up-with` to scale the storage tier:

```bash
just up-with 3 3    # 3 compute nodes + 3 storage nodes
```

storage-01 keeps running an NFS server (the default cluster behavior).
storage-02..M come up with `DISABLE_NFS_AUTOSTART=1` — sshd is reachable,
`/data` is an empty scratch volume, and no NFS server is started. These
bare nodes are intended for installing a distributed filesystem (BeeGFS,
Ceph, etc.) under your own configuration.

Storage-02..M use the reserved IP range `NETWORK.240-249` (see
[NAMING.md](NAMING.md)) so they never collide with compute nodes.

### Maximum Node Count

- **Compute nodes:** Up to 10 (compute-01..compute-10, IPs `NETWORK.3-13`)
- **Storage nodes:** Up to 10 (storage-01 at `NETWORK.5`, storage-02..10
  at `NETWORK.240-248`)
- **Head nodes:** 1 (cannot be scaled, contains management functions)

### Checking Cluster Status

View running nodes:

```bash
just status
```

List all containers:

```bash
docker ps --filter "name=lci-"
```

### Troubleshooting Scale Issues

**Problem: IP address conflict**

- Ensure each node has a unique IP address
- Use the `hostname -I` command inside containers to verify

**Problem: Container name collision**

- Each `container_name` must be unique
- Format: `lci-{role}-{NN}` (e.g., lci-compute-03, lci-storage-02)

**Problem: Service not starting**

- Check logs: `docker-compose logs compute3`
- Verify dependencies: All compute nodes depend on head node

## Cluster Architecture

| Node     | Hostname   | Container Name | IP Address | SSH Port | Role         |
| -------- | ---------- | -------------- | ---------- | -------- | ------------ |
| head     | head-01    | lci-head-01    | 10.0.10.2  | 2222     | Login node   |
| compute1 | compute-01 | lci-compute-01 | 10.0.10.3  | -        | Compute node |
| compute2 | compute-02 | lci-compute-02 | 10.0.10.4  | -        | Compute node |
| storage  | storage-01 | lci-storage-01 | 10.0.10.5  | -        | NFS/Storage  |

### Storage Node Access

The storage node has SSH access from the head node for testing storage solutions
(BeeGFS, ZFS, etc.):

```bash
# After SSHing to head node as rocky and elevating to root
ssh root@compute-01
ssh root@compute-02
ssh root@storage-01
```

The `rocky` user cannot SSH between nodes - only `root` has inter-node access.

## Common Commands

```bash
# List running containers
docker ps

# View container logs
docker logs lci-head-01

# Execute command in container
docker exec -it lci-head-01 bash

# Stop containers
just down

# Clean up everything (images, volumes, networks)
just clean
```

## Ansible Configuration (Optional)

Run Ansible playbook after containers are up:

```bash
just ansible-run
```

## Troubleshooting

### SSH connection refused

- Ensure containers are running: `docker ps`
- Check if SSH is running: `docker logs lci-head-01`
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

| Action                | Configs (/etc) | Data (/var) | Installed Software (/usr) |
| --------------------- | -------------- | ----------- | ------------------------- |
| Container restart     | Preserved      | Preserved   | Preserved                 |
| `just down` / `up-ms` | **Lost**       | **Lost**    | **Lost**                  |
| Image rebuild         | **Lost**       | **Lost**    | **Lost**                  |

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
docker exec -it lci-head-01 dnf -y install <package>

# Make config changes (persists until volume is removed)
docker exec -it lci-head-01 vi /etc/some/config
```

### Using Ansible for Configuration

For reproducible configuration, use Ansible to apply changes after each cluster
start:

```bash
# Add your tasks to ansible/playbook.yml
just ansible-run
```

This approach ensures configuration is applied consistently after every cluster
rebuild.
