#!/usr/bin/env bash
#
# test.sh - Tests for the diagnostic-tool Docker image.
#
# Builds the image (if not already present) and exercises the CLI commands
# through `docker run`, covering help, system, disk and invalid-command
# handling as required by the assignment brief.
#
set -uo pipefail

IMAGE="diagnostic-tool:test"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }

if ! command -v docker >/dev/null 2>&1; then
    echo "docker is not installed or not on PATH - cannot run tests." >&2
    exit 1
fi

echo "== Building image (${IMAGE}) =="
if ! docker build -t "${IMAGE}" "${SCRIPT_DIR}" >/tmp/diagnostic-build.log 2>&1; then
    echo "Docker build failed. Log:" >&2
    cat /tmp/diagnostic-build.log >&2
    exit 1
fi
pass "docker build succeeded"

echo
echo "== help command =="
OUTPUT=$(docker run --rm "${IMAGE}" help 2>&1)
RC=$?
if [ "${RC}" -eq 0 ] && echo "${OUTPUT}" | grep -qi "Usage"; then
    pass "help exits 0 and prints usage"
else
    fail "help did not behave as expected (exit=${RC})"
fi

echo
echo "== system command =="
OUTPUT=$(docker run --rm "${IMAGE}" system 2>&1)
RC=$?
if [ "${RC}" -eq 0 ] && echo "${OUTPUT}" | grep -qi "Hostname"; then
    pass "system exits 0 and prints system info"
else
    fail "system did not behave as expected (exit=${RC})"
fi

echo
echo "== disk command =="
OUTPUT=$(docker run --rm "${IMAGE}" disk 2>&1)
RC=$?
if [ "${RC}" -eq 0 ] && echo "${OUTPUT}" | grep -qi "Disk Usage"; then
    pass "disk exits 0 and prints disk usage"
else
    fail "disk did not behave as expected (exit=${RC})"
fi

echo
echo "== network command (missing host) =="
docker run --rm "${IMAGE}" network >/dev/null 2>&1
RC=$?
if [ "${RC}" -eq 2 ]; then
    pass "network with no host exits 2"
else
    fail "network with no host should exit 2 (got ${RC})"
fi

echo
echo "== invalid command =="
docker run --rm "${IMAGE}" bogus-command >/dev/null 2>&1
RC=$?
if [ "${RC}" -eq 2 ]; then
    pass "invalid command exits 2"
else
    fail "invalid command should exit 2 (got ${RC})"
fi

echo
echo "== default CMD (no args) =="
OUTPUT=$(docker run --rm "${IMAGE}" 2>&1)
RC=$?
if [ "${RC}" -eq 0 ] && echo "${OUTPUT}" | grep -qi "Usage"; then
    pass "default command (no args) shows help"
else
    fail "default command did not behave as expected (exit=${RC})"
fi

echo
echo "=============================="
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "=============================="

if [ "${FAIL}" -gt 0 ]; then
    exit 1
fi
exit 0
