#!/bin/bash
set -e

# When DISABLE_NFS_AUTOSTART=1, come up as a bare host: skip the loop-backed
# /export setup and the NFS server. Used by storage-CC-2..M overlays so the node
# is ready for the user to install BeeGFS/Ceph/Lustre on /data. sshd is run by
# supervisord independently and keeps the container alive.
if [ "${DISABLE_NFS_AUTOSTART:-0}" = "1" ]; then
  echo "DISABLE_NFS_AUTOSTART=1: skipping NFS setup; /data is bare scratch"
  exec tail -f /dev/null
fi

SIZE_GB=${STORAGE_SIZE_GB:-10}
BACKING=/data/storage.img
MOUNTPOINT=/export

# Back /export with a loop-mounted ext4 image on the /data volume so the export
# behaves like a real, fixed-size filesystem and survives restarts.
mkdir -p /data
if [ ! -f "$BACKING" ]; then
  fallocate -l ${SIZE_GB}G "$BACKING"
  mkfs.ext4 -F "$BACKING"
fi

mkdir -p "$MOUNTPOINT"
if ! mountpoint -q "$MOUNTPOINT"; then
  LOOPDEV=$(losetup -f --show "$BACKING")
  mount "$LOOPDEV" "$MOUNTPOINT" || { echo "mount of $BACKING failed"; exit 1; }
fi

# Serve /export over NFSv4 with userspace nfs-ganesha. The in-kernel NFS server
# is unavailable here (the Docker Desktop LinuxKit kernel has no nfsd module),
# so ganesha is the only path that actually listens on 2049. Clients mount with
# `-o nfsvers=4` (see the mount-scratch Ansible play). Run in the foreground so
# this stays the live process under supervisord.
mkdir -p /var/run/ganesha /var/log
echo "Starting nfs-ganesha (NFSv4) exporting $MOUNTPOINT"
exec /usr/bin/ganesha.nfsd -F -L /var/log/ganesha.log -f /etc/ganesha/ganesha.conf
