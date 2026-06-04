## Ansible usage (dynamic inventory)

This project includes a dynamic inventory plugin configuration
`containers.docker.yml` that uses the `community.docker.docker_containers`
plugin to discover running containers on the local Docker daemon and connect to
them over the Docker API (no in-container sshd or mapped SSH port required).

The filename **must** end in `docker.yml`/`docker.yaml` — the plugin only
verifies inventory files with that suffix. Renaming it away from that silently
breaks discovery.

Prerequisites:

- ansible (core 2.16+ recommended; tested on 2.20)
- community.docker collection
  (`ansible-galaxy collection install community.docker`, or
  `just install-collections`)
- just (optional) for the convenience recipes

How it works:

- The inventory includes only containers whose name starts with the configured
  prefix (default `lci-`; override with the `LCI_PREFIX` env var).
- Containers are grouped by role parsed from the name
  `{PREFIX}-{role}-{CC}-{N}`: `role_head`, `role_compute`, `role_storage`, plus
  a combined `nfs_clients` group (head + compute) used for the `/scratch` mount
  play.

How to run:

1. Start the cluster (e.g. `just up`, `just setup`, or a template like
   `just intro`).
2. Provision NFS `/scratch` on head + compute:

   ```sh
   just mount-scratch
   ```

   This runs `playbook.yml` against the live cluster, mounting the storage
   node's `/export` as `/scratch` and making it persistent (an `/etc/fstab`
   entry plus a supervisord boot hook that re-mounts on container restart).

   `just mount-scratch` passes `LCI_PREFIX` / `LCI_CLUSTER_NUM` through so the
   inventory filter and the NFS-server fallback name match the values in the
   `Justfile`.

Notes:

- `inventory.ini` is a static, hand-edited fallback inventory and is not used by
  any recipe; the dynamic `containers.docker.yml` is the supported path.
- The plugin reads the local Docker socket by default. For a remote/relocated
  socket, adjust `docker_host` in `containers.docker.yml`.
