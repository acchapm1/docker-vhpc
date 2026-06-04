# Container Naming Convention

## Naming Scheme

All containers and hostnames follow the Linux Cluster Institute (LCI) lab HPC
naming convention so scripts and labs stay consistent with that environment:

```
{PREFIX}-{role}-{CC}-{N}
```

- `PREFIX`: Name prefix (default: `lci`). Applied to **both** the container name
  and the hostname so they are identical.
- `role`: `head`, `compute`, or `storage`
- `CC`: **Virtual cluster number** — each student is assigned one (zero-padded,
  e.g. `01`, `02`, `04`). The same number is used across every node in that
  student's cluster.
- `N`: **Per-role instance number** — a 1-based counter for multiples of a node
  type (`-1`, `-2`, `-3`, ...). Not zero-padded.

The container name and the hostname are always the same string. So for the
assigned cluster number `04` with the default `lci` prefix, the nodes are
`lci-head-04-1`, `lci-compute-04-1`, `lci-compute-04-2`, `lci-storage-04-1`,
`lci-storage-04-2`, and so on.

### Default Cluster Configuration (cluster number `01`, prefix `lci`)

| Role      | Container Name = Hostname | IP Address | SSH Port |
| --------- | ------------------------- | ---------- | -------- |
| Head      | `lci-head-01-1`           | 10.0.10.2  | 2222     |
| Compute 1 | `lci-compute-01-1`        | 10.0.10.3  | -        |
| Compute 2 | `lci-compute-01-2`        | 10.0.10.4  | -        |
| Storage 1 | `lci-storage-01-1`        | 10.0.10.5  | -        |

`CC` here is `01`; the trailing `N` distinguishes the two compute nodes (`-1`,
`-2`).

### Setting the Cluster Number

Each student sets their assigned cluster number once in the `Justfile`:

```bash
CLUSTER_NUM := "04"
```

This flows through `generate-config` into both the container name and the
hostname (which are identical). With cluster number `04` (and the default `lci`
prefix):

- `lci-head-04-1`
- `lci-compute-04-1`
- `lci-compute-04-2`
- `lci-storage-04-1`

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

The hostname matches the container name exactly (`lci-head-02-1`,
`lci-compute-02-1`, ...).

### Scalable Naming

When you scale the cluster with `just up-with N M`, the per-role instance number
(`N`) continues sequentially. Compute and storage live in separate IP ranges so
they can grow independently without collision. The examples below use cluster
number `01`.

| Additional Compute | Container Name = Hostname | IP Address |
| ------------------ | ------------------------- | ---------- |
| Compute 3          | `lci-compute-01-3`        | 10.0.10.6  |
| Compute 4          | `lci-compute-01-4`        | 10.0.10.7  |
| Compute 5          | `lci-compute-01-5`        | 10.0.10.8  |
| ...                | ...                       | ...        |
| Compute 10         | `lci-compute-01-10`       | 10.0.10.13 |

Compute formula: compute instance `N` for `N >= 3` → `NETWORK.(N+3)`. The `+3`
offset skips over storage instance 1 at `NETWORK.5`.

| Additional Storage | Container Name = Hostname | IP Address  |
| ------------------ | ------------------------- | ----------- |
| Storage 2          | `lci-storage-01-2`        | 10.0.10.240 |
| Storage 3          | `lci-storage-01-3`        | 10.0.10.241 |
| ...                | ...                       | ...         |
| Storage 10         | `lci-storage-01-10`       | 10.0.10.248 |

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
ssh root@lci-compute-01-1
ssh root@lci-compute-01-2
ssh root@lci-storage-01-1
```

**Docker Commands:**

```bash
# View all cluster containers (default prefix)
docker ps --filter "name=lci-"

# Execute command in head node
docker exec -it lci-head-01-1 bash

# View logs
docker logs lci-head-01-1
docker logs lci-compute-01-1
```

**Inside Containers:**

```bash
# Ping other nodes by hostname
ping lci-compute-01-1
ping lci-compute-01-2
ping lci-storage-01-1

# SSH between nodes (as root)
ssh root@lci-compute-01-1
ssh root@lci-storage-01-1
```

### Benefits of This Naming

- **Matches the LCI lab convention** so labs and scripts transfer directly
- **Per-student isolation** via the cluster number (`CC`)
- **Clear role + instance identification** via `{role}-{CC}-{N}`
- **Scalable** — instance number grows independently per role
- **Hostname = container name** — one identifier to remember per node
