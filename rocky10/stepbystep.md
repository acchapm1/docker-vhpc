# Step by Step: Default Cluster (Rocky 9)

Bring up the default cluster (1 head + 2 compute + 1 storage) and SSH in.

## Bring up the cluster

```bash
cd docker-vhpc/rocky10
just setup
```

`just setup` runs `generate-config + build + up + copy-ssh-key + status` and
prints the final container list.

## Verify it's up

```bash
just status
```

You should see four containers (names follow `{PREFIX}-{role}-{CC}-{N}`, and the
hostname matches the container name exactly; defaults use prefix `lci` and
cluster number `01`):

| Container = Hostname | IP        |
| -------------------- | --------- |
| `lci-head-01-1`      | 10.0.10.2 |
| `lci-compute-01-1`   | 10.0.10.3 |
| `lci-compute-01-2`   | 10.0.10.4 |
| `lci-storage-01-1`   | 10.0.10.5 |

## SSH into the head node

From your host machine:

```bash
ssh rocky@localhost -p 2222
```

Password: `Sp@rky26`

Once logged in, elevate to root (no password):

```bash
sudo -i
```

## SSH from the head node to compute / storage

`just setup` already distributed the root SSH key from the head node to all the
other nodes. From inside the head node (as root):

```bash
ssh root@lci-compute-01-1
ssh root@lci-compute-01-2
ssh root@lci-storage-01-1
```

No password needed.

## Tear it down

```bash
just down
```

This stops the containers and removes their volumes (destroys data).
