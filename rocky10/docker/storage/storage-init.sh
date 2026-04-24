#!/bin/bash
set -e
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
