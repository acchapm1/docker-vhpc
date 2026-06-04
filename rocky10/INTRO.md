# `just intro` on Rocky 10: not available (and what to do instead)

This document explains why the **`just intro`** (NFS `/scratch`) template is not
available on the **Rocky Linux 10.1** variant, what to do if you need it, and
confirms that **`just inter`** works here as usual.

## TL;DR

| Template      | rocky9 | rocky10 | Why                                              |
| ------------- | :----: | :-----: | ------------------------------------------------ |
| `just inter`  |   ✅   |   ✅    | Drive tooling (xfsprogs/lvm2/losetup) is in EL10 |
| `just intro`  |   ✅   |   ❌    | `nfs-ganesha` is not packaged for EL10           |

- **`just inter` is fully supported on Rocky 10.** It brings up 1 head + 2
  compute + 4 storage, each storage node exposing two raw, unformatted 5g block
  devices (`/dev/vdb`, `/dev/vdc`) for parallel-filesystem labs.
- **`just intro` (shared NFS `/scratch`) is intentionally omitted from Rocky
  10.** Use the **`rocky9/`** variant if you need the NFS-scratch workflow.

## `just inter` — supported on Rocky 10

```bash
cd rocky10
just inter
```

Each storage node (`lci-storage-01-1` .. `lci-storage-01-4`) comes up bare (no
NFS) with stable, raw devices you format yourself:

```bash
docker exec lci-storage-01-1 lsblk
docker exec lci-storage-01-1 blkid /dev/vdb        # empty => raw, no filesystem
docker exec lci-storage-01-1 mkfs.xfs  /dev/vdb    # XFS (BeeGFS/Lustre OSD)
docker exec lci-storage-01-1 pvcreate  /dev/vdc    # LVM PV (LVM/Ceph)
```

The required tools (`xfsprogs`, `lvm2`, `e2fsprogs`, `util-linux`) are all in the
Rocky 10 baseos repo, so nothing special is needed — this template works the same
as it does on Rocky 9.

## Why `just intro` (NFS `/scratch`) does not work on Rocky 10

The Intro template shares a `/scratch` directory across the head and compute
nodes over NFS. That requires an **NFS server** running inside the storage
container. On Docker Desktop, there are only two ways to provide one, and neither
is available on Rocky 10:

1. **In-kernel NFS server (`rpc.nfsd`)** — unavailable. Docker Desktop runs a
   LinuxKit VM whose kernel ships **no `nfsd` module** (`modprobe nfsd` →
   "Module nfsd not found"). `rpc.nfsd` registers with rpcbind but nothing ever
   listens on port 2049, so clients get "Connection refused". This is true on
   both Rocky 9 and Rocky 10.

2. **Userspace NFS server (`nfs-ganesha`)** — this is what the **rocky9** Intro
   template uses, and it is **not packaged for EL10**:
   - The CentOS Storage SIG has **no EL10 release RPM**
     (`centos-release-nfs-ganesha*` exists only for el9).
   - `nfs-ganesha` is absent from EPEL/CRB/baseos on Rocky 10.
   - Even its dependency `libntirpc` is not in the EL10 repos, so installing the
     el9 RPMs on Rocky 10 fails dependency resolution.

With no kernel nfsd and no ganesha package, there is no straightforward NFS
server to run, so the Intro template is omitted from `rocky10/` rather than
shipped broken.

## If you need NFS `/scratch` on Rocky 10

In rough order of effort:

### Option 1 — Use the rocky9 variant (recommended)

The simplest path. `rocky9/` provides a fully working `just intro`:

```bash
cd ../rocky9
just intro
```

The compute side (your jobs) is Rocky 9.7 rather than 10.1, but the NFS-scratch
workflow is identical and already tested.

### Option 2 — Mixed-OS: Rocky 9 storage node under a Rocky 10 cluster

Keep head/compute on Rocky 10.1 but build **only the storage image** from
`rockylinux:9.7` so it can install `nfs-ganesha`. The storage node only serves
files, so a different base OS there is harmless. Sketch:

- Point `rocky10/docker/storage/Dockerfile` `FROM` lines at `rockylinux:9.7`.
- Restore the ganesha install + `ganesha.conf` + the ganesha branch of
  `storage-init.sh` from the `rocky9/` variant.
- Re-add the `intro` / `mount-scratch` recipes and the `ansible/` directory from
  `rocky9/`.

This is essentially porting Phase 1 with a pinned storage base image; see the
`rocky9/` files as the reference implementation.

### Option 3 — Build `nfs-ganesha` from source on Rocky 10

Compile `libntirpc` + `nfs-ganesha` from source inside the storage image. Fully
Rocky 10, but adds a slow, heavy, maintenance-prone build step. Only worth it if
a single-OS Rocky 10 cluster with NFS is a hard requirement.

### Option 4 — Re-check package availability over time

The CentOS Storage SIG may publish `nfs-ganesha` for EL10 in the future. Re-test
with:

```bash
docker run --rm rockylinux/rockylinux:10.1 bash -lc \
  'dnf -y install epel-release >/dev/null 2>&1; \
   dnf list available "centos-release-nfs-ganesha*" "nfs-ganesha*" 2>/dev/null \
   | grep -i ganesha || echo "still not packaged for EL10"'
```

If it becomes available, porting Intro to rocky10 is then the same work as in
`rocky9/` (storage Dockerfile + `ganesha.conf` + `storage-init.sh` NFS branch +
the `intro`/`mount-scratch` recipes and `ansible/` setup).
