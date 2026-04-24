FROM rockylinux/rockylinux:9.7 AS builder
RUN dnf -y update && \
    dnf -y install epel-release && \
    dnf -y install nfs-utils e2fsprogs util-linux supervisor bzip2 openssh-server passwd vim wget && \
    dnf -y clean all

FROM rockylinux/rockylinux:9.7 AS runtime
COPY --from=builder /usr/sbin /usr/sbin
COPY --from=builder /sbin /sbin
RUN dnf -y install epel-release && \
    dnf -y install nfs-utils e2fsprogs util-linux supervisor openssh-server ncurses vim wget && \
    dnf -y clean all

RUN useradd -m -s /bin/bash rocky && \
    echo "rocky:Sp@rky26" | chpasswd && \
    echo "root:root" | chpasswd

COPY start-storage.sh /usr/local/bin/start-storage.sh
COPY storage-init.sh /usr/local/bin/storage-init.sh
COPY supervisord.conf /etc/supervisord.conf
RUN chmod +x /usr/local/bin/start-storage.sh /usr/local/bin/storage-init.sh

EXPOSE 22 2049 111
CMD ["/usr/local/bin/start-storage.sh"]
