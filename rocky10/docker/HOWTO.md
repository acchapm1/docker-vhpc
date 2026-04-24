## Multi-stage variant (brief HOWTO)

1. Build images: cd multi-stage docker-compose build

2. Start cluster: docker-compose up -d

3. SSH into head: ssh root@localhost -p 2222 (password: root)

4. Mount NFS on nodes if needed: mkdir -p /shared && mount -t nfs
   172.28.10.5:/export /shared

5. Teardown: docker-compose down --volumes --remove-orphans
