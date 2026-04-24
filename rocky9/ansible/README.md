## Ansible usage (dynamic inventory)

This project includes a dynamic inventory plugin configuration
`docker_containers.yml` that uses the `community.docker.docker_containers`
plugin to discover running containers on the local Docker daemon.

Prerequisites:

- ansible (2.14+ recommended)
- community.docker collection (install with
  `ansible-galaxy collection install community.docker`)
- just (optional) for running convenience tasks

How to run (example):

1. Start one of the cluster variants (multi-stage or slim-runtime): just up-ms #
   or: just up-slim

2. Run the playbook using the dynamic inventory: just ansible-run
   # this will install the community.docker collection if needed and execute ansible-playbook
   # The playbook will use SSH connections to the containers. Make sure root password is 'root'
   # or that you have copied your SSH public key into the containers' /root/.ssh/authorized_keys.

Notes:

- The inventory filters for container names beginning with 'ms-hpc-' or
  'slim-hpc-'. Adjust if you change service names.
- The plugin reads the local Docker socket by default. If your Docker socket is
  at a different path or remote, adjust docker_host.
