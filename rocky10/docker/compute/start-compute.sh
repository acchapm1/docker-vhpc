#!/bin/bash
mkdir -p /var/run/sshd /var/log/supervisor
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
  ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' -q
fi
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
  ssh-keygen -t rsa -b 2048 -f /etc/ssh/ssh_host_rsa_key -N '' -q
fi
exec /usr/bin/supervisord -c /etc/supervisord.conf
