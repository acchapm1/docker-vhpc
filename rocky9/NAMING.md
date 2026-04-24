# Container Naming Convention

## New Naming Scheme (as of this update)

All containers and hostnames now follow a consistent pattern without the `hpc-`
prefix and using zero-padded numbers.

### Default Cluster Configuration

| Role      | Container Name   | Hostname     | IP Address  | SSH Port |
| --------- | ---------------- | ------------ | ----------- | -------- |
| Head      | `lci-head-01`    | `head-01`    | 172.29.10.2 | 2222     |
| Compute 1 | `lci-compute-01` | `compute-01` | 172.29.10.3 | -        |
| Compute 2 | `lci-compute-02` | `compute-02` | 172.29.10.4 | -        |
| Storage   | `lci-storage-01` | `storage-01` | 172.29.10.5 | -        |

### Naming Pattern

**Container Names:** `{VARIANT}-{role}-{NN}`

- `VARIANT`: Configurable prefix (default: `lci`)
- `role`: `head`, `compute`, or `storage`
- `NN`: Zero-padded number (01, 02, 03, etc.)

**Hostnames:** `{role}-{NN}`

- No domain suffix (no `.node`)
- Consistent with container naming

### Scalable Naming

When you scale the cluster, the naming continues sequentially:

| Additional Compute | Container Name   | Hostname     | IP Address   |
| ------------------ | ---------------- | ------------ | ------------ |
| Compute 3          | `lci-compute-03` | `compute-03` | 172.29.10.6  |
| Compute 4          | `lci-compute-04` | `compute-04` | 172.29.10.7  |
| Compute 5          | `lci-compute-05` | `compute-05` | 172.29.10.8  |
| ...                | ...              | ...          | ...          |
| Compute 10         | `lci-compute-10` | `compute-10` | 172.29.10.11 |

| Additional Storage | Container Name   | Hostname     | IP Address   |
| ------------------ | ---------------- | ------------ | ------------ |
| Storage 2          | `lci-storage-02` | `storage-02` | 172.29.10.12 |
| Storage 3          | `lci-storage-03` | `storage-03` | 172.29.10.13 |

### Usage Examples

**SSH Access:**

```bash
# From host machine to head node
ssh rocky@localhost -p 2222

# From head node to other nodes (after sudo -i)
ssh root@compute-01
ssh root@compute-02
ssh root@storage-01
```

**Docker Commands:**

```bash
# View all cluster containers
docker ps --filter "name=lci-"

# Execute command in head node
docker exec -it lci-head-01 bash

# View logs
docker logs lci-head-01
docker logs lci-compute-01
```

**Inside Containers:**

```bash
# Ping other nodes by hostname
ping compute-01
ping compute-02
ping storage-01

# SSH between nodes (as root)
ssh root@compute-01
ssh root@storage-01
```

### Changing the VARIANT Prefix

Edit Justfile line 8 to change the prefix:

```bash
VARIANT := "mycluster"
```

This would result in:

- `mycluster-head-01`
- `mycluster-compute-01`
- `mycluster-storage-01`

### Benefits of New Naming

✅ **Consistent format** - All names follow same pattern ✅ **Zero-padded
numbers** - Proper sorting (01, 02, ..., 10) ✅ **No redundant prefixes** -
Removed `hpc-` from names ✅ **Clear identification** - Easy to identify role
and number ✅ **Scalable** - Works for up to 99 nodes per role ✅ **Shorter
hostnames** - Easier to type and read

### Migration from Old Naming

**Old naming (deprecated):**

- `lci-hpc-head` → `head.node`
- `lci-hpc-compute1` → `compute1.node`
- `lci-hpc-storage` → `storage.node`

**New naming (current):**

- `lci-head-01` → `head-01`
- `lci-compute-01` → `compute-01`
- `lci-storage-01` → `storage-01`

All scripts, documentation, and templates have been updated to use the new
naming convention.
