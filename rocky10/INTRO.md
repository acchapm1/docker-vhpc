# `just intro` on Rocky 10: NFS `/scratch` (storage node runs Rocky 9)

Both predefined templates work on the **Rocky Linux 10.1** variant:

| Template     | Provides                                         | Storage server         |
| ------------ | ------------------------------------------------ | ---------------------- |
| `just intro` | shared NFS `/scratch` on head + compute          | nfs-ganesha (NFSv4)    |
| `just inter` | 4 storage nodes with raw `/dev/vdb` + `/dev/vdc` | none (bare PFS targets)|

This document explains one deliberate quirk of `just intro` on Rocky 10: the
**storage node image is built from Rocky Linux 9.7, not 10.1**.

## Why the storage node is Rocky 9

`just intro` shares `/scratch` over NFS. The Docker Desktop LinuxKit kernel has
**no in-kernel NFS server** (`modprobe nfsd` fails), so the storage node runs a
**userspace NFS server, nfs-ganesha**.

- On **EL9** that is **nfs-ganesha 5** — stable, and what the `rocky9/` variant
  uses.
- On **EL10** the only build is **nfs-ganesha 9** (from the CentOS Stream 10
  Storage SIG mirror). It *installs* fine, but in this container setup it is
  **not stable**: it SIGSEGVs under supervisord and fails NFSv4/TCP RPC
  registration. (See the "Future work" note below.)

So this variant uses a **mixed-OS cluster**: head and compute are Rocky 10.1, but
the **storage node is pinned to `rockylinux:9.7`** in
`docker/storage/Dockerfile`. The storage node only serves files (NFS) and PFS
drives, so a different base OS there is harmless and invisible to users — the
cluster behaves exactly like the rocky9 Intro template.

```bash
cd rocky10
just intro          # head/compute = Rocky 10.1, storage = Rocky 9.7

docker exec lci-head-01-1    cat /etc/rocky-release   # Rocky Linux 10.1
docker exec lci-storage-01-1 cat /etc/rocky-release   # Rocky Linux 9.7
```

## Using `just intro`

```bash
cd rocky10
just intro
```

This runs: generate config → build → start → wire passwordless SSH → mount
`/scratch` (via Ansible) → status. The `/scratch` mount is persistent (re-mounts
after `docker restart`) and is applied with Ansible from a self-contained
**uv**-managed Python 3.12 environment (`just ansible-setup`, invoked
automatically). See the repo `README.md`/`HOWTO.md` for the uv prerequisite.

```bash
# Verify the shared scratch round-trips across nodes:
docker exec lci-head-01-1     bash -lc 'echo hi > /scratch/test.txt'
docker exec lci-compute-01-1  cat /scratch/test.txt    # -> hi
docker exec lci-compute-01-2  cat /scratch/test.txt    # -> hi
```

`just inter` (the raw-drive PFS template) is fully Rocky 10 — it needs no NFS
server, so its storage nodes are not affected by this.

## Future work: native nfs-ganesha on Rocky 10

When time permits, revisit making the storage node fully Rocky 10.1 with native
nfs-ganesha 9. What is already known:

- The packages exist on the CentOS Stream 10 Storage SIG mirror and install via a
  manual repo file (there is no `centos-release-nfs-ganesha*` enabler RPM for
  el10):

  ```ini
  # /etc/yum.repos.d/centos-nfsganesha9.repo
  [centos-nfsganesha9]
  name=CentOS Stream 10 - Storage SIG - NFS Ganesha 9
  baseurl=https://mirror.stream.centos.org/SIGs/10-stream/storage/$basearch/nfsganesha-9/
  gpgcheck=0
  enabled=1
  ```

- ganesha 9 needs `Enable_UDP = false;` in `NFS_CORE_PARAM` (otherwise it aborts
  trying to register NFSv3/UDP).

- Open problems to solve: it SIGSEGVs when run under supervisord (stable when run
  directly), and logs `Cannot register NFS V4 on TCP` (wants rpcbind). Likely
  needs: running ganesha outside supervisord (or as a proper service), running
  `rpcbind`, and possibly tuning the RPC registration so it does not depend on
  the portmapper. ganesha 9 is stable in an isolated container, so the issue is
  the container/supervisord integration, not the package itself.
