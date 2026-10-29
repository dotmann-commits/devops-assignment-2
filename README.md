# Assignment 2: Dockerized Diagnostic CLI

A Bash diagnostic tool (`app/diagnostic.sh`) packaged in a Docker image. You can run it with `docker run` or Docker Compose.

## Files

```
assignment-2/
├── README.md
├── app/
│   ├── diagnostic.sh
│   └── health-check.sh
├── Dockerfile
├── compose.yaml
├── .dockerignore
├── test.sh
└── grade.sh
```

## Requirements

Docker with Compose v2 (`docker compose`).

## Setup

```bash
git clone <repo-url>
cd assignment-2
chmod +x grade.sh test.sh app/*.sh
docker build -t diagnostic-tool .
```

## Commands

```
diagnostic system           system information
diagnostic network <host>   check a host
diagnostic disk             disk usage
diagnostic help             list commands
```

With docker run:

```bash
docker run --rm diagnostic-tool system
docker run --rm diagnostic-tool disk
docker run --rm diagnostic-tool network example.com
docker run --rm diagnostic-tool help
```

With Compose:

```bash
docker compose run --rm diagnostic system
docker compose run --rm diagnostic disk
docker compose run --rm diagnostic network example.com
docker compose run --rm diagnostic help
```

Exit codes:

| Code | Meaning |
|------|---------|
| 0 | success |
| 1 | the check failed |
| 2 | unknown command or missing argument |

For example `diagnostic network` with no host prints an error and exits 2.

## Dockerfile

- Uses `alpine:3.20` to keep the image small
- Installs bash, coreutils, iputils (ping) and bind-tools (dig)
- Only copies the `app/` folder, everything else is in .dockerignore
- Runs as a non-root user called `diag`
- Has a HEALTHCHECK that runs `app/health-check.sh`
- ENTRYPOINT is the script and CMD is `help`, so running the image with no arguments shows the help text

## Testing

```bash
./test.sh
./grade.sh
```

`test.sh` builds the image and runs help, system, disk, network with no host, an invalid command and no command. It checks the output and exit code of each one.

`grade.sh` also checks the folder structure, syntax, permissions, the Dockerfile, .dockerignore, compose.yaml and the git history.

## Notes

- I used Alpine as the lightweight base image.
- The container does not keep any state between runs.
- No secrets or credentials are needed.

## Git

The Dockerfile, Compose file and tests were built on the `feature/dockerize` branch and merged into main.
