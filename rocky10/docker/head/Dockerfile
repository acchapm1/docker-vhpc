# Builder stage - install and prepare packages
FROM rockylinux/rockylinux:10.1 AS builder
RUN dnf -y update && \
    dnf -y install epel-release && \
    dnf -y install passwd openssh-server openssh-clients sudo vim tar iputils which \
                   nfs-utils python3 supervisor bzip2 tmux neovim wget && \
    dnf -y clean all

# Runtime stage - small image with only runtime deps
FROM rockylinux/rockylinux:10.1 AS runtime
# Copy necessary runtime files from builder stage
COPY --from=builder /usr/bin /usr/bin
COPY --from=builder /usr/sbin /usr/sbin
COPY --from=builder /etc /etc
RUN dnf -y install epel-release && \
    dnf -y install nfs-utils openssh-server supervisor ncurses sudo && \
    dnf -y clean all

# Create users: rocky for external access, root for inter-node
# Add rocky to wheel group with passwordless sudo
RUN useradd -m -s /bin/bash -G wheel rocky && \
    echo "rocky:Sp@rky26" | chpasswd && \
    echo "root:root" | chpasswd && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Setup supervisord to run sshd
COPY supervisord.conf /etc/supervisord.conf
COPY start-head.sh /usr/local/bin/start-head.sh
RUN chmod +x /usr/local/bin/start-head.sh

EXPOSE 22
CMD ["/usr/local/bin/start-head.sh"]
