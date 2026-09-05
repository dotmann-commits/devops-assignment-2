#!/usr/bin/env bash
#
# health-check.sh - Simple container health check used by Docker's
# HEALTHCHECK instruction. Verifies the diagnostic CLI is present,
# executable, and responds correctly to its 'help' command.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIAGNOSTIC="${SCRIPT_DIR}/diagnostic.sh"

if [ ! -x "${DIAGNOSTIC}" ]; then
    echo "unhealthy: ${DIAGNOSTIC} not found or not executable"
    exit 1
fi

if "${DIAGNOSTIC}" help >/dev/null 2>&1; then
    echo "healthy"
    exit 0
else
    echo "unhealthy: diagnostic.sh help failed"
    exit 1
fi
