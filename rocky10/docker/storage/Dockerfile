# NOTE: this storage image is pinned to Rocky Linux 9.7, NOT 10.1 like the head
# and compute nodes. This is a deliberate mixed-OS setup. The storage node only
# serves files (NFS) and PFS drives, so a different base OS here is harmless.
#
# Why 9.7: the `just intro` template needs a userspace NFS server (the Docker
# Desktop LinuxKit kernel has no in-kernel nfsd module). On EL9 that is
# nfs-ganesha 5, which is stable. The EL10 build (nfs-ganesha 9, from the CentOS
# Stream 10 Storage SIG) installs but is NOT stable in this container setup
# (SIGSEGV under supervisord, NFSv4/TCP registration failures). Until that is
# sorted, the storage node uses the proven Rocky 9 ganesha. See README.md
# ("Storage node runs Rocky 9") for the follow-up to revisit native EL10 ganesha.
FROM rockylinux/rockylinux:9.7 AS builder
RUN dnf -y update && \
    dnf -y install epel-release && \
    dnf -y install nfs-utils e2fsprogs util-linux supervisor bzip2 openssh-server passwd vim wget && \
    dnf -y clean all

FROM rockylinux/rockylinux:9.7 AS runtime
COPY --from=builder /usr/sbin /usr/sbin
COPY --from=builder /sbin /sbin
# Userspace NFS server (nfs-ganesha 5) from the CentOS Storage SIG for the Intro
# /scratch export, plus drive tooling (xfsprogs/lvm2/e2fsprogs) for the Inter
# template's raw PFS devices.
RUN dnf -y install epel-release centos-release-nfs-ganesha5 && \
    dnf -y install nfs-utils e2fsprogs xfsprogs lvm2 util-linux supervisor openssh-server ncurses vim wget \
                   nfs-ganesha nfs-ganesha-vfs && \
    dnf -y clean all

RUN useradd -m -s /bin/bash rocky && \
    echo "rocky:Sp@rky26" | chpasswd && \
    echo "root:root" | chpasswd

COPY start-storage.sh /usr/local/bin/start-storage.sh
COPY storage-init.sh /usr/local/bin/storage-init.sh
COPY ganesha.conf /etc/ganesha/ganesha.conf
COPY supervisord.conf /etc/supervisord.conf
RUN chmod +x /usr/local/bin/start-storage.sh /usr/local/bin/storage-init.sh

EXPOSE 22 2049
CMD ["/usr/local/bin/start-storage.sh"]
