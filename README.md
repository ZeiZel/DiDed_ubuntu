# Working Ubuntu

For what:

- use as consistent working environment on any machine
- use docker inside docker (DiD)
- if you are unable to use WSL, you can up all in Docker
- dockerconainers, bro

## How to start

### Fill envs

Create `.env` based on `.env.example` and you should change:

- `USER_NAME` - yor created username for system
- `WORKING_DIRECTORY` - your base system working path

### Build image

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

### Connect to image

```bash
docker exec -it ubuntu-dev-systemd zsh
```

## TODO

- [ ] Need to create more comprehensive dots clone script (now it works only with stow-based configs)
