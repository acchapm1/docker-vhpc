# SPECS.md - Virtual HPC Docker Cluster Specification

Complete specification for building a Docker-based virtual HPC cluster. This
document contains all requirements needed to recreate the solution from scratch.

## Project Overview

**Goal**: Create a multi-node virtual HPC (High Performance Computing) cluster
using Docker containers for testing, development, and learning purposes.

**Key Features**:

- Multi-node architecture (head, compute, storage)
- Scalable compute nodes (1-10 nodes)
- Shared NFS storage across all nodes
- Passwordless SSH between all nodes
- Template-based configuration
- Task runner for lifecycle management

## Architecture

### Node Types

| Node Type | Count | Purpose                            | IP Pattern             |
| --------- | ----- | ---------------------------------- | ---------------------- |
| Head      | 1     | Login/management node, SSH gateway | {NETWORK}.2            |
| Compute   | 1-10  | Processing workers                 | {NETWORK}.3, .4, .5... |
| Storage   | 1     | NFS server for shared storage      | {NETWORK}.5            |

### Network Topology

- **Driver**: Docker bridge network
- **Subnet**: {NETWORK}.0/24 (default: 10.0.10.0/24)
- **Naming**: Container names follow `{VARIANT}-{role}-{NN}` pattern
- **External Access**: SSH on host port {PORT} (default: 2222) → head node port
  22

## Configuration Parameters

All values must be configurable via a single source of truth:

| Parameter      | Default | Description                    |
| -------------- | ------- | ------------------------------ |
| PORT           | 2222    | External SSH port              |
| NETWORK        | 10.0.10 | Docker subnet (first 3 octets) |
| VARIANT        | asu     | Container name prefix          |
| COMPUTE_NODES  | 2       | Number of compute nodes (1-10) |
| STORAGE_NODES  | 1       | Number of storage nodes (1-3)  |
| COMPUTE_MEMORY | 2g      | Memory limit per compute node  |
| STORAGE_SIZE   | 10g     | Size of storage backing file   |

## Base Image Requirements

- **Primary**: Rocky Linux 9.7 (rockylinux/rockylinux:9.7)
- **Alternative**: Rocky Linux 10.1 (rockylinux/rockylinux:10.1)
- **Build Pattern**: Multi-stage builds (builder + runtime stages)

## Docker Image Specifications

### Head Node

**Purpose**: Management/login node with external SSH access

**Packages Required**:

- openssh-server, openssh-clients
- passwd, sudo
- vim, tmux, neovim, wget
- nfs-utils
- python3
- supervisor
- bzip2, tar, iputils, which

**Users**:

- `rocky`: External access user (password: Sp@rky26), member of wheel group
- `root`: Administrative user (password: root)

**Sudo Configuration**:

- Wheel group has passwordless sudo: `%wheel ALL=(ALL) NOPASSWD: ALL`

**Volumes**:

- head-etc → /etc
- head-var → /var/log

**Ports**: 22 (SSH)

**Privileges**: true (required for NFS)

### Compute Node

**Purpose**: Worker node for processing tasks

**Packages Required**:

- openssh-server
- passwd, sudo
- vim, tmux, neovim, wget
- nfs-utils
- supervisor
- bzip2

**Users**: Same as head node (rocky, root)

**Volumes**:

- compute{N}-etc → /etc
- compute{N}-var → /var/log

**Resource Limits**:

- mem_limit: {COMPUTE_MEMORY}
- cpus: "1.0"

**Ports**: 22 (SSH)

**Privileges**: true

### Storage Node

**Purpose**: NFS server providing shared storage

**Packages Required**:

- openssh-server
- passwd
- vim, wget
- nfs-utils
- e2fsprogs, util-linux
- supervisor
- bzip2

**Users**: Same as head node (rocky, root)

**Volumes**:

- storage-data → /export (NFS export)
- storage-var → /var/log
- storage-backing → /data

**Ports**: 22 (SSH), 2049 (NFS), 111 (rpcbind)

**Privileges**: true (required for NFS)

## Container Startup Script Requirements

All nodes require startup scripts that:

1. Create required directories:

   ```bash
   mkdir -p /var/run/sshd /var/log/supervisor
   ```

2. Generate SSH host keys if missing:

   ```bash
   if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
     ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' -q
   fi
   if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
     ssh-keygen -t rsa -b 2048 -f /etc/ssh/ssh_host_rsa_key -N '' -q
   fi
   ```

3. Start supervisord:

   ```bash
   exec /usr/bin/supervisord -c /etc/supervisord.conf
   ```

## Supervisord Configuration

All nodes require supervisord to manage sshd:

```ini
[supervisord]
nodaemon=true

[program:sshd]
command=/usr/sbin/sshd -D
autostart=true
stdout_logfile=/var/log/sshd.out
stderr_logfile=/var/log/sshd.err
```

## Docker Compose Requirements

### Service Definitions

1. **Head Service**:
   - Build from ./head
   - Expose port {PORT}:22
   - Static IP: {NETWORK}.2
   - Depends on: none

2. **Compute Services** (1-N):
   - Use service extension pattern
   - Static IPs: {NETWORK}.3, .4, .5...
   - Resource limits applied
   - Depends on: head

3. **Storage Service**:
   - Build from ./storage
   - Static IP: {NETWORK}.5
   - Depends on: head

4. **Service Extension Template**:
   - Define `compute_definition` as reusable base
   - Contains build path, volumes, privileged settings

### Network Configuration

```yaml
networks:
  hpcnet:
    driver: bridge
    ipam:
      config:
        - subnet: {NETWORK}.0/24
```

### Volume Naming

Pattern: `{role}{N}-{purpose}` (e.g., `compute1-etc`, `storage-data`)

## Template System

### Variable Substitution

Templates use `{{VARIABLE}}` syntax and are processed by a generation script:

**Required Template Variables**:

- {{PORT}}
- {{NETWORK}}
- {{VARIANT}}
- {{COMPUTE_MEMORY}}

**Template Files**:

- docker-compose.yml.template → docker-compose.yml
- cluster-config.yml.template → cluster-config.yml

**Generation Script** (gen-config.sh):

```bash
#!/bin/bash
PORT="${PORT:-2222}"
NETWORK="${NETWORK:-172.29.10}"
VARIANT="${VARIANT:-lci}"
COMPUTE_MEMORY="${COMPUTE_MEMORY:-2g}"

sed \
    -e "s|{{PORT}}|$PORT|g" \
    -e "s|{{NETWORK}}|$NETWORK|g" \
    -e "s|{{VARIANT}}|$VARIANT|g" \
    -e "s|{{COMPUTE_MEMORY}}|$COMPUTE_MEMORY|g" \
    docker-compose.yml.template > docker-compose.yml
```

## Task Runner Requirements

### Required Commands

**Lifecycle**:

- `setup`: Full setup (generate config, build, start, copy SSH keys, show
  status)
- `generate-config`: Generate docker-compose.yml from templates
- `build`: Build all Docker images
- `up`: Start cluster
- `down`: Stop and remove containers/volumes
- `clean`: Remove all containers, images, volumes

**Operations**:

- `status`: Show running containers filtered by variant
- `logs [service]`: View container logs
- `exec "cmd"`: Execute command in head node
- `ssh rocky`: SSH into head node
- `copy-ssh-key`: Distribute SSH keys for passwordless access

**Validation**:

- `validate`: Validate docker-compose and ansible syntax
- `ansible-run`: Run Ansible playbook with optional dry-run

**Scalability**:

- `init-cluster N`: Generate config for N compute nodes
- `up-with N`: Start cluster with N compute nodes

### SSH Key Distribution Requirements

The `copy-ssh-key` command must:

1. Find user's public SSH key (check in order):
   - ~/.ssh/id_vhpc.pub
   - ~/.ssh/id_ed25519.pub
   - ~/.ssh/id_rsa.pub

2. Copy public key to root's authorized_keys on all containers

3. Generate SSH keypair on head node (if missing)

4. Copy head node's public key to all other nodes for inter-node communication

5. Set proper permissions:
   - ~/.ssh: 700
   - ~/.ssh/authorized_keys: 600

## Ansible Integration

### Inventory Requirements

Use dynamic Docker inventory plugin:

- Plugin: community.docker.docker_containers
- Connection type: SSH
- Filter containers by name prefix matching {VARIANT}

### Playbook Requirements

Playbooks should:

- Use FQCN (e.g., `ansible.builtin.yum`)
- Set `gather_facts: no` for speed
- Use `become: yes` for privilege escalation
- Handle optional NFS mount with `ignore_errors: yes`

### Required Tasks

1. Install packages (vim, python3, nfs-utils)
2. Ensure /shared directory exists
3. Mount NFS share (if storage reachable)
4. Configure SSH authorized_keys

## File Structure

```
project-root/
├── Justfile                          # Task runner with all configuration
├── README.md                         # Project documentation
├── AGENTS.md                         # AI agent guidelines
├── docker/
│   ├── docker-compose.yml.template   # Template for compose file
│   ├── docker-compose.yml            # Generated (gitignored)
│   ├── cluster-config.yml.template   # Template for scaling
│   ├── cluster-config.yml            # Generated (gitignored)
│   ├── gen-config.sh                 # Template processor
│   ├── head/
│   │   ├── Dockerfile
│   │   ├── start-head.sh
│   │   └── supervisord.conf
│   ├── compute/
│   │   ├── Dockerfile
│   │   ├── start-compute.sh
│   │   └── supervisord.conf
│   └── storage/
│       ├── Dockerfile
│       ├── start-storage.sh
│       ├── storage-init.sh
│       └── supervisord.conf
└── ansible/
    ├── playbook.yml
    └── docker_containers.yml         # Dynamic inventory
```

## Testing & Validation Criteria

### Functional Requirements

1. **Cluster Startup**:
   - All containers start successfully
   - All nodes can ping each other
   - SSH service running on all nodes

2. **External Access**:
   - Can SSH to head node via port 2222
   - rocky user can authenticate with password
   - rocky user has sudo access

3. **Inter-node Communication**:
   - Passwordless SSH between all nodes
   - Head node can SSH to compute/storage nodes
   - All nodes can resolve hostnames

4. **Shared Storage** (if NFS configured):
   - /shared directory exists on all nodes
   - Storage node exports /export via NFS
   - All nodes can mount NFS share

5. **Scalability**:
   - Can scale to 10 compute nodes
   - IP addressing follows pattern
   - Container naming follows pattern

### Validation Commands

```bash
# Syntax validation
just validate

# Container status
just status

# SSH connectivity
just ssh rocky

# Inter-node SSH
just exec "ssh compute-01 hostname"

# NFS check
just exec "showmount -e storage-01"
```

## Security Requirements

1. **Passwords**: Never commit real passwords to version control
2. **SSH Keys**: Generate at runtime, never commit
3. **Privileged Mode**: Required for NFS, acknowledge security implications
4. **Generated Files**: docker-compose.yml must be gitignored (contains resolved
   values)

## Success Criteria

An AI tool successfully completes this task if:

1. ✅ Creates working multi-node Docker cluster
2. ✅ All containers start and remain running
3. ✅ External SSH access works on port 2222
4. ✅ Passwordless SSH between nodes configured
5. ✅ Configuration is template-driven
6. ✅ Task runner provides all required commands
7. ✅ Can scale compute nodes 1-10
8. ✅ Follows naming conventions exactly
9. ✅ Uses multi-stage Docker builds
10. ✅ Generated files are gitignored

## Implementation Notes

### Design Decisions

1. **Why Just over Make**: Cleaner syntax, better variable handling
2. **Why supervisord**: Container needs PID 1 that reaps zombies
3. **Why privileged mode**: Required for NFS kernel server
4. **Why multi-stage builds**: Reduces final image size
5. **Why template system**: Single source of truth for configuration

### Known Limitations

- NFS requires privileged containers (security consideration)
- No persistent storage across `just down` (by design)
- Single storage node (distributed storage requires manual config)
- No Slurm/PBS scheduler (can be added via Ansible)

## Version Variants

The solution should support multiple OS versions in parallel directories:

- `rocky9/` - Rocky Linux 9.7 implementation
- `rocky10/` - Rocky Linux 10.1 implementation

Each variant must have identical structure and functionality, differing only in
base image version.
