#!/bin/bash
set -e

# When DISABLE_NFS_AUTOSTART=1, come up as a bare host: skip the loop-backed
# /export setup and the NFS export. Used by storage-02..M overlays so the
# node is ready for the user to install BeeGFS/Ceph on /data. sshd is run by
# supervisord independently and keeps the container alive.
if [ "${DISABLE_NFS_AUTOSTART:-0}" = "1" ]; then
  echo "DISABLE_NFS_AUTOSTART=1: skipping NFS setup; /data is bare scratch"
  exec tail -f /dev/null
fi

SIZE_GB=${STORAGE_SIZE_GB:-10}
BACKING=/data/storage.img
MOUNTPOINT=/export

mkdir -p /data
if [ ! -f "$BACKING" ]; then
  fallocate -l ${SIZE_GB}G $BACKING
  mkfs.ext4 -F $BACKING
fi

mkdir -p $MOUNTPOINT
LOOPDEV=$(losetup -f --show $BACKING)
mount $LOOPDEV $MOUNTPOINT || { echo "mount failed"; exit 1; }

echo "$MOUNTPOINT *(rw,no_root_squash,async,no_subtree_check)" > /etc/exports
rpcbind
/usr/sbin/exportfs -rav

echo "NFS storage initialized"
exec tail -f /dev/null
