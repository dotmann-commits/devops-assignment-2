#!/usr/bin/env bash
#
# diagnostic.sh - Bash CLI diagnostic tool, designed to run standalone or
# inside a Docker container.
#
# Usage:
#   diagnostic system
#   diagnostic network <host>
#   diagnostic disk
#   diagnostic help
#
# Exit codes:
#   0 - success
#   1 - operational/runtime failure
#   2 - invalid command or input
#
set -uo pipefail

PROG_NAME="diagnostic"

print_help() {
    cat <<EOF
${PROG_NAME} - Linux diagnostic CLI

Usage:
  ${PROG_NAME} system              Display Linux system information
  ${PROG_NAME} network <host>      Check connectivity to a host
  ${PROG_NAME} disk                Display disk usage information
  ${PROG_NAME} help                Show this help message

Exit codes:
  0  success
  1  operational/runtime failure
  2  invalid command or input
EOF
}

cmd_system() {
    echo "== Hostname =="
    hostname 2>/dev/null || echo "unknown"

    echo
    echo "== Current User =="
    whoami

    echo
    echo "== Date/Time =="
    date '+%Y-%m-%d %H:%M:%S %Z'

    echo
    echo "== Operating System =="
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "${PRETTY_NAME:-$NAME}"
    else
        uname -s
    fi

    echo
    echo "== Kernel Version =="
    uname -r

    echo
    echo "== Uptime =="
    uptime 2>/dev/null || echo "unavailable"

    echo
    echo "== CPU Information =="
    if [ -f /proc/cpuinfo ]; then
        grep -m1 'model name' /proc/cpuinfo | sed 's/model name[[:space:]]*: //' || echo "unknown"
        echo "Cores: $(grep -c ^processor /proc/cpuinfo)"
    else
        echo "unavailable"
    fi

    echo
    echo "== Memory Information =="
    if command -v free >/dev/null 2>&1; then
        free -h
    else
        echo "unavailable"
    fi

    return 0
}

cmd_network() {
    local host="${1:-}"
    if [ -z "${host}" ]; then
        echo "Error: 'network' requires a <host> argument." >&2
        print_help >&2
        return 2
    fi

    if [[ "${host}" == -* ]] || ! [[ "${host}" =~ ^[A-Za-z0-9.-]+$ ]]; then
        echo "Error: '${host}' is not a valid hostname or IP address." >&2
        return 2
    fi

    local ok=0

    echo "== Host Resolution =="
    local resolved=""
    if command -v getent >/dev/null 2>&1; then
        resolved=$(getent hosts "${host}" 2>/dev/null | awk '{print $1}' | head -n1)
    fi
    if [ -z "${resolved}" ] && command -v dig >/dev/null 2>&1; then
        resolved=$(dig +short "${host}" 2>/dev/null | head -n1)
    fi
    if [ -n "${resolved}" ]; then
        echo "Resolved address: ${resolved}"
    else
        echo "Resolved address: unable to resolve '${host}'"
        ok=1
    fi

    echo
    echo "== Connectivity Check (ping) =="
    if command -v ping >/dev/null 2>&1; then
        if ping -c 1 -W 2 "${host}" >/dev/null 2>&1; then
            echo "Ping: SUCCESS - ${host} is reachable"
        else
            echo "Ping: FAILED - ${host} did not respond"
            ok=1
        fi
    else
        echo "Ping: SKIPPED - ping command not available"
    fi

    if [ "${ok}" -ne 0 ]; then
        return 1
    fi
    return 0
}

cmd_disk() {
    echo "== Disk Usage =="
    if command -v df >/dev/null 2>&1; then
        df -h
    else
        echo "Error: df command not available." >&2
        return 1
    fi
    return 0
}

main() {
    local command="${1:-}"
    shift || true

    case "${command}" in
        system)
            cmd_system
            exit $?
            ;;
        network)
            cmd_network "$@"
            exit $?
            ;;
        disk)
            cmd_disk
            exit $?
            ;;
        help|--help|-h)
            print_help
            exit 0
            ;;
        "")
            echo "Error: no command supplied." >&2
            print_help >&2
            exit 2
            ;;
        *)
            echo "Error: unknown command '${command}'." >&2
            print_help >&2
            exit 2
            ;;
    esac
}

main "$@"
