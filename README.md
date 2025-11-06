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

Docker compose (the best way):

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
docker exec -it -u <your_user> <container_name> /bin/zsh
# docker exec -it -u zeizel ubuntu-systemd /bin/zsh
```

## Troubleshooting

### Image not pull automatically

You may need to install image manually

```bash
docker pull ubuntu:24.04
```

### Windows

#### Git bash

Because on win bash convert `/` paths to `C:/Users/<user>/AppData/Local/Programs/Git/`, we might have some problems with it :/

Solve is: 
1. just not using `bash` and go to `powershell` or `cmd`
2. use `export MSYS_NO_PATHCONV=1`

## TODO

- [ ] Need to create more comprehensive dots clone script (now it works only with stow-based configs)
