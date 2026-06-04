#!/bin/bash
set -e

# Set up extra raw block devices for PFS labs (BeeGFS/Lustre/Ceph). Driven by:
#   EXTRA_DRIVES        space-separated device names, e.g. "vdb vdc"
#   EXTRA_DRIVE_SIZE_GB sparse size of each backing image (default 5)
#   EXTRA_DRIVE_DIR     where the backing .img files live (default /drives)
# For each name, ensure a sparse backing image exists, attach it to a loop
# device, and symlink /dev/<name> to whatever loop got assigned so lab device
# names are stable (NOTE: /dev/vdb often pre-exists as a host virtio passthrough
# in Docker Desktop, so the symlink intentionally replaces it). Deliberately NO
# mkfs: drives ship raw for students to format. Idempotent on every boot.
#
# Loop devices are a HOST-GLOBAL resource shared by every container. With 4
# storage nodes x 2 drives starting at once, `losetup -f` races: two containers
# can pick the same free number, and `losetup -f` can even return a /dev/loopN
# whose device node doesn't exist inside this container. Mitigations below:
#   1. Pre-create loop nodes /dev/loop0..MAXLOOP so a chosen number always has a
#      node (privileged container, so mknod is allowed).
#   2. Retry the find-free -> attach cycle with jitter; on collision the loser
#      gets EBUSY/ENOENT and simply tries the next free number.
MAXLOOP=63

ensure_loop_nodes() {
  # major 7 = loop. Create any missing /dev/loopN so losetup never points at a
  # node that doesn't exist in this container's /dev.
  local i
  [ -e /dev/loop-control ] || mknod /dev/loop-control c 10 237 2>/dev/null || true
  for i in $(seq 0 "$MAXLOOP"); do
    [ -e "/dev/loop${i}" ] || mknod "/dev/loop${i}" b 7 "$i" 2>/dev/null || true
  done
}

attach_loop() {
  # echo the loop device backing "$1", reusing an existing attachment or
  # attaching fresh with retries to survive cross-container races.
  local img="$1" loopdev tries
  loopdev=$(losetup -j "$img" -O NAME -n 2>/dev/null | head -n1)
  if [ -n "$loopdev" ]; then echo "$loopdev"; return 0; fi
  for tries in $(seq 1 20); do
    if loopdev=$(losetup -f --show "$img" 2>/dev/null) && [ -n "$loopdev" ]; then
      echo "$loopdev"; return 0
    fi
    # Lost the race (or hit a missing node) — back off a random bit and retry.
    sleep "0.$(( (RANDOM % 5) + 1 ))"
  done
  return 1
}

setup_extra_drives() {
  [ -n "${EXTRA_DRIVES:-}" ] || return 0
  local size_gb="${EXTRA_DRIVE_SIZE_GB:-5}"
  local dir="${EXTRA_DRIVE_DIR:-/drives}"
  mkdir -p "$dir"
  ensure_loop_nodes
  local name img loopdev
  for name in $EXTRA_DRIVES; do
    img="$dir/${name}.img"
    if [ ! -f "$img" ]; then
      echo "Creating ${size_gb}G sparse backing image $img"
      truncate -s "${size_gb}G" "$img"
    fi
    if ! loopdev=$(attach_loop "$img"); then
      echo "WARNING: could not attach a loop device for $img (loop pool busy)" >&2
      continue
    fi
    ln -sfn "$loopdev" "/dev/${name}"
    echo "Drive /dev/${name} -> ${loopdev} (${size_gb}G, raw/unformatted)"
  done
}

setup_extra_drives

# When DISABLE_NFS_AUTOSTART=1, come up as a bare host: skip the loop-backed
# /export setup and the NFS server. Used by storage-CC-2..M overlays and the
# Inter template so the node is ready for the user to install BeeGFS/Ceph/Lustre.
# Any extra drives above are already set up; sshd is run by supervisord and keeps
# the container alive.
if [ "${DISABLE_NFS_AUTOSTART:-0}" = "1" ]; then
  echo "DISABLE_NFS_AUTOSTART=1: skipping NFS setup; node is bare (extra drives ready)"
  exec tail -f /dev/null
fi

# NFS is NOT served on Rocky 10: nfs-ganesha is not packaged for EL10 (the
# CentOS Storage SIG has no EL10 release), and the in-kernel NFS server is
# unavailable under Docker Desktop (no nfsd module). The shared-NFS `/scratch`
# Intro template therefore lives in the rocky9/ variant. Here, the storage node
# just stays up (sshd via supervisord); any extra drives were set up above. The
# Inter template always sets DISABLE_NFS_AUTOSTART=1 and never reaches this path.
echo "Rocky 10 storage node: NFS server not available on EL10 (use rocky9/ for"
echo "the NFS /scratch Intro template). Node is up; sshd is served by supervisord."
exec tail -f /dev/null
