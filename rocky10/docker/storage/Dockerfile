FROM rockylinux/rockylinux:10.1 AS builder
RUN dnf -y update && \
    dnf -y install epel-release && \
    dnf -y install nfs-utils e2fsprogs xfsprogs lvm2 util-linux supervisor bzip2 openssh-server passwd vim wget && \
    dnf -y clean all

FROM rockylinux/rockylinux:10.1 AS runtime
COPY --from=builder /usr/sbin /usr/sbin
COPY --from=builder /sbin /sbin
# Drive tooling for the Inter template's raw PFS devices: xfsprogs (mkfs.xfs),
# lvm2 (pvcreate), e2fsprogs (mkfs.ext4), util-linux (losetup). NOTE: rocky10
# storage serves NO NFS — nfs-ganesha is unavailable on EL10, so the Intro
# /scratch template lives in rocky9/. Storage nodes here come up bare
# (DISABLE_NFS_AUTOSTART=1) with raw /dev/vdb + /dev/vdc for PFS labs.
RUN dnf -y install epel-release && \
    dnf -y install nfs-utils e2fsprogs xfsprogs lvm2 util-linux supervisor openssh-server ncurses vim wget && \
    dnf -y clean all

RUN useradd -m -s /bin/bash rocky && \
    echo "rocky:Sp@rky26" | chpasswd && \
    echo "root:root" | chpasswd

COPY start-storage.sh /usr/local/bin/start-storage.sh
COPY storage-init.sh /usr/local/bin/storage-init.sh
COPY supervisord.conf /etc/supervisord.conf
RUN chmod +x /usr/local/bin/start-storage.sh /usr/local/bin/storage-init.sh

EXPOSE 22
CMD ["/usr/local/bin/start-storage.sh"]
