# Container Naming Convention

## Naming Scheme

All containers and hostnames follow the Linux Cluster Institute (LCI) lab HPC
naming convention so scripts and labs stay consistent with that environment:

```
{PREFIX}-{role}-{CC}-{N}
```

- `PREFIX`: Container name prefix (default: `asu`). Hostnames omit the prefix.
- `role`: `head`, `compute`, or `storage`
- `CC`: **Virtual cluster number** — each student is assigned one (zero-padded,
  e.g. `01`, `02`, `04`). The same number is used across every node in that
  student's cluster.
- `N`: **Per-role instance number** — a 1-based counter for multiples of a node
  type (`-1`, `-2`, `-3`, ...). Not zero-padded.

So for the assigned cluster number `04`, the nodes are `head-04-1`,
`compute-04-1`, `compute-04-2`, `storage-04-1`, `storage-04-2`, and so on.

### Default Cluster Configuration (cluster number `01`, prefix `asu`)

| Role      | Container Name     | Hostname       | IP Address | SSH Port |
| --------- | ------------------ | -------------- | ---------- | -------- |
| Head      | `asu-head-01-1`    | `head-01-1`    | 10.0.10.2  | 2222     |
| Compute 1 | `asu-compute-01-1` | `compute-01-1` | 10.0.10.3  | -        |
| Compute 2 | `asu-compute-01-2` | `compute-01-2` | 10.0.10.4  | -        |
| Storage 1 | `asu-storage-01-1` | `storage-01-1` | 10.0.10.5  | -        |

`CC` here is `01`; the trailing `N` distinguishes the two compute nodes (`-1`,
`-2`).

### Setting the Cluster Number

Each student sets their assigned cluster number once in the `Justfile`:

```bash
CLUSTER_NUM := "04"
```

This flows through `generate-config` into both container names and hostnames.
With cluster number `04` (and the default `asu` prefix):

- `asu-head-04-1` → `head-04-1`
- `asu-compute-04-1` → `compute-04-1`
- `asu-compute-04-2` → `compute-04-2`
- `asu-storage-04-1` → `storage-04-1`

### Changing the Prefix

Edit the `PREFIX` variable in the `Justfile`:

```bash
PREFIX := "lci"
```

Combined with `CLUSTER_NUM := "02"`, the head node becomes `lci-head-02-1` and
every other node follows the same `{PREFIX}-{role}-{CC}-{N}` pattern:

- `lci-head-02-1`
- `lci-compute-02-1`
- `lci-compute-02-2`
- `lci-storage-02-1`

Hostnames always drop the prefix (`head-02-1`, `compute-02-1`, ...).

### Scalable Naming

When you scale the cluster with `just up-with N M`, the per-role instance number
(`N`) continues sequentially. Compute and storage live in separate IP ranges so
they can grow independently without collision. The examples below use cluster
number `01`.

| Additional Compute | Container Name      | Hostname        | IP Address |
| ------------------ | ------------------- | --------------- | ---------- |
| Compute 3          | `asu-compute-01-3`  | `compute-01-3`  | 10.0.10.6  |
| Compute 4          | `asu-compute-01-4`  | `compute-01-4`  | 10.0.10.7  |
| Compute 5          | `asu-compute-01-5`  | `compute-01-5`  | 10.0.10.8  |
| ...                | ...                 | ...             | ...        |
| Compute 10         | `asu-compute-01-10` | `compute-01-10` | 10.0.10.13 |

Compute formula: compute instance `N` for `N >= 3` → `NETWORK.(N+3)`. The `+3`
offset skips over storage instance 1 at `NETWORK.5`.

| Additional Storage | Container Name      | Hostname        | IP Address  |
| ------------------ | ------------------- | --------------- | ----------- |
| Storage 2          | `asu-storage-01-2`  | `storage-01-2`  | 10.0.10.240 |
| Storage 3          | `asu-storage-01-3`  | `storage-01-3`  | 10.0.10.241 |
| ...                | ...                 | ...             | ...         |
| Storage 10         | `asu-storage-01-10` | `storage-01-10` | 10.0.10.248 |

Storage formula: storage instance `N` for `N >= 2` → `NETWORK.(238+N)`. Storage
instance 1 stays at `NETWORK.5` for backward compatibility; storage instances
2..M use the reserved `NETWORK.240-249` range so they never collide with compute
instances for `N <= 10`.

**Bare vs. NFS:** storage instance 1 runs an NFS server by default. Storage
instances 2..M come up with `DISABLE_NFS_AUTOSTART=1` set — sshd + an empty
`/data` scratch volume, no NFS — ready for you to install BeeGFS, Ceph, or
another distributed filesystem.

### Usage Examples

These examples assume cluster number `01`.

**SSH Access:**

```bash
# From host machine to head node
ssh rocky@localhost -p 2222

# From head node to other nodes (after sudo -i)
ssh root@compute-01-1
ssh root@compute-01-2
ssh root@storage-01-1
```

**Docker Commands:**

```bash
# View all cluster containers (default prefix)
docker ps --filter "name=asu-"

# Execute command in head node
docker exec -it asu-head-01-1 bash

# View logs
docker logs asu-head-01-1
docker logs asu-compute-01-1
```

**Inside Containers:**

```bash
# Ping other nodes by hostname
ping compute-01-1
ping compute-01-2
ping storage-01-1

# SSH between nodes (as root)
ssh root@compute-01-1
ssh root@storage-01-1
```

### Benefits of This Naming

- **Matches the LCI lab convention** so labs and scripts transfer directly
- **Per-student isolation** via the cluster number (`CC`)
- **Clear role + instance identification** via `{role}-{CC}-{N}`
- **Scalable** — instance number grows independently per role
- **Shorter hostnames** — prefix is dropped from hostnames
