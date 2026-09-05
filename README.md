# Assignment 2 — Dockerized Diagnostic CLI

A Bash diagnostic CLI (`diagnostic.sh`) packaged as a lightweight Docker
image, runnable via `docker run` or Docker Compose.

## Structure

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

- Docker (or a Docker-compatible engine) with Docker Compose v2
  (`docker compose ...`).

## Installation / Setup

```bash
git clone <your-repository-url>
cd assignment-2
chmod +x grade.sh test.sh app/*.sh
docker build -t diagnostic-tool .
```

## Usage

### CLI commands

```
diagnostic system              # display Linux system information
diagnostic network <host>      # check connectivity to a host
diagnostic disk                # display disk usage information
diagnostic help                # display commands and usage
```

### Via `docker run`

```bash
docker build -t diagnostic-tool .
docker run --rm diagnostic-tool system
docker run --rm diagnostic-tool disk
docker run --rm diagnostic-tool network example.com
docker run --rm diagnostic-tool help
```

### Via Docker Compose

```bash
docker compose run --rm diagnostic system
docker compose run --rm diagnostic disk
docker compose run --rm diagnostic network example.com
docker compose run --rm diagnostic help
```

### Exit codes

| Code | Meaning                        |
|------|---------------------------------|
| 0    | success                         |
| 1    | operational/runtime failure     |
| 2    | invalid command or input        |

Invalid commands and missing required arguments (e.g. `diagnostic network`
with no host) are handled explicitly and exit `2` rather than crashing the
script.

## Dockerfile notes

- Base image: `alpine:3.20` (lightweight).
- Installs only what's needed to run the CLI: `bash`, `coreutils`,
  `iputils` (for `ping`), `bind-tools` (for `dig`).
- Copies only `app/` into the image (everything else is excluded via
  `.dockerignore`).
- Runs as a non-root user (`diag`).
- Defines a `HEALTHCHECK` backed by `app/health-check.sh`.
- `ENTRYPOINT ["/app/diagnostic.sh"]` with `CMD ["help"]`, so
  `docker run diagnostic-tool` with no arguments shows usage, and
  `docker run diagnostic-tool <command>` runs that command directly.

## Testing

```bash
chmod +x grade.sh test.sh app/*.sh
./test.sh     # runs the Docker-image test suite directly
./grade.sh    # full grading script (structure, syntax, Docker, tests, Git)
```

`test.sh` builds the image and exercises `help`, `system`, `disk`,
`network` (missing-host case), an invalid command, and the default
(no-args) command — verifying both output and exit codes.

`grade.sh` additionally checks the repository structure, Bash syntax,
executable permissions, `Dockerfile`/`.dockerignore` contents,
`compose.yaml`, and basic Git history (5+ commits, a merged feature
branch).

## Assumptions

- "Lightweight Linux base image" is interpreted as Alpine Linux, which
  keeps the final image small while still providing the diagnostic tools
  needed (`ping`, `dig`, `df`, etc.) via a minimal package set.
- The container has no persistent state; each `docker run` is independent.
- No secrets or credentials are used or required by the image.

## Git Workflow

Built with a `feature/dockerize` branch used to develop the Dockerfile,
Compose file and test suite in isolation, later merged into `main` — see
`git log --graph --oneline --all` for the full history.
