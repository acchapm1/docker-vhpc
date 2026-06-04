FROM rockylinux/rockylinux:9.7 AS builder
RUN dnf -y update && \
    dnf -y install epel-release && \
    dnf -y install nfs-utils e2fsprogs util-linux supervisor bzip2 openssh-server passwd vim wget && \
    dnf -y clean all

FROM rockylinux/rockylinux:9.7 AS runtime
COPY --from=builder /usr/sbin /usr/sbin
COPY --from=builder /sbin /sbin
# Userspace NFS server (nfs-ganesha) from the CentOS Storage SIG: the LinuxKit
# kernel under Docker Desktop has no nfsd module, so the in-kernel NFS server
# cannot run. ganesha exports /export over NFSv4 entirely in userspace.
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
