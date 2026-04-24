FROM rockylinux/rockylinux:9.7 AS builder
RUN dnf -y update && \
    dnf -y install epel-release && \
    dnf -y install passwd openssh-server sudo supervisor nfs-utils bzip2 tmux neovim wget && \
    dnf -y clean all

FROM rockylinux/rockylinux:9.7 AS runtime
COPY --from=builder /usr/bin /usr/bin
COPY --from=builder /usr/sbin /usr/sbin
RUN dnf -y install epel-release && \
    dnf -y install openssh-server supervisor nfs-utils ncurses && \
    dnf -y clean all

RUN useradd -m -s /bin/bash rocky && \
    echo "rocky:Sp@rky26" | chpasswd && \
    echo "root:root" | chpasswd

COPY supervisord.conf /etc/supervisord.conf
COPY start-compute.sh /usr/local/bin/start-compute.sh
RUN chmod +x /usr/local/bin/start-compute.sh

EXPOSE 22
CMD ["/usr/local/bin/start-compute.sh"]
