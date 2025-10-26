# Working Ubuntu

For what:
- use as consistent working environment on any machine
- use docker inside docker (DiD)
- if you are unable to use WSL, you can up all in Docker
- dockerconainers, bro

# How to start

Docker compose:

```bash
docker compose up -d
```

Docker run:

```bash
docker run -itd \
  --privileged \
  --cgroupns=host \
  --name ubuntu-dev-systemd \
  --volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
  --tmpfs /run \
  --tmpfs /run/lock \
  ubuntu-dev:latest \
  /sbin/init
```
