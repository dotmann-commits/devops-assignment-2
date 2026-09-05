#!/usr/bin/env bash
#
# grade.sh - Local grading/verification script for Assignment 2.
#
# Checks project structure, Bash syntax, executable permissions, Dockerfile
# and .dockerignore presence, image build, basic container commands,
# invalid-command handling, Docker Compose configuration, the student test
# suite, and basic Git history.
#
set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
info() { echo; echo "== $1 =="; }

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info "Project structure"
for f in README.md app/diagnostic.sh app/health-check.sh Dockerfile compose.yaml .dockerignore test.sh grade.sh; do
    if [ -e "${f}" ]; then
        pass "found ${f}"
    else
        fail "missing ${f}"
    fi
done

info "Bash syntax"
for f in app/diagnostic.sh app/health-check.sh test.sh; do
    if [ -f "${f}" ]; then
        if bash -n "${f}" 2>/dev/null; then
            pass "${f} syntax OK"
        else
            fail "${f} has syntax errors"
        fi
    fi
done

info "Executable permissions"
for f in app/diagnostic.sh app/health-check.sh test.sh grade.sh; do
    if [ -f "${f}" ]; then
        if [ -x "${f}" ]; then
            pass "${f} is executable"
        else
            fail "${f} is not executable (run: chmod +x ${f})"
        fi
    fi
done

info "Dockerfile"
if [ -f Dockerfile ]; then
    grep -qi '^FROM' Dockerfile && pass "Dockerfile has a FROM instruction" || fail "Dockerfile missing FROM"
    grep -qi '^COPY' Dockerfile && pass "Dockerfile copies application files" || fail "Dockerfile missing COPY"
    if grep -qiE '^(ENTRYPOINT|CMD)' Dockerfile; then
        pass "Dockerfile defines ENTRYPOINT and/or CMD"
    else
        fail "Dockerfile missing ENTRYPOINT/CMD"
    fi
else
    fail "Dockerfile not found"
fi

info ".dockerignore"
if [ -f .dockerignore ]; then
    if grep -q '\.git' .dockerignore; then
        pass ".dockerignore excludes .git"
    else
        fail ".dockerignore should exclude .git"
    fi
else
    fail ".dockerignore not found"
fi

info "Docker Compose configuration"
if [ -f compose.yaml ]; then
    grep -qi 'services:' compose.yaml && pass "compose.yaml defines services" || fail "compose.yaml missing services key"
else
    fail "compose.yaml not found"
fi

info "Docker image build and container commands"
if command -v docker >/dev/null 2>&1; then
    IMAGE="diagnostic-tool:grade"
    if docker build -t "${IMAGE}" . >/tmp/assignment2-build.log 2>&1; then
        pass "docker build succeeds"

        HELP_OUTPUT=$(docker run --rm "${IMAGE}" help 2>&1)
        if echo "${HELP_OUTPUT}" | grep -qi "usage"; then
            pass "container 'help' command works"
        else
            fail "container 'help' command did not produce expected output"
        fi

        SYSTEM_OUTPUT=$(docker run --rm "${IMAGE}" system 2>&1)
        if echo "${SYSTEM_OUTPUT}" | grep -qi "hostname"; then
            pass "container 'system' command works"
        else
            fail "container 'system' command did not produce expected output"
        fi

        DISK_OUTPUT=$(docker run --rm "${IMAGE}" disk 2>&1)
        if echo "${DISK_OUTPUT}" | grep -qi "disk usage"; then
            pass "container 'disk' command works"
        else
            fail "container 'disk' command did not produce expected output"
        fi

        docker run --rm "${IMAGE}" bogus-command >/dev/null 2>&1
        RC=$?
        if [ "${RC}" -eq 2 ]; then
            pass "container rejects invalid command with exit 2"
        else
            fail "container should exit 2 on invalid command (got ${RC})"
        fi
    else
        fail "docker build failed (see /tmp/assignment2-build.log)"
    fi
else
    fail "docker is not installed - cannot verify image build/run"
fi

info "Student test suite (test.sh)"
if [ -x test.sh ]; then
    if command -v docker >/dev/null 2>&1; then
        if ./test.sh >/tmp/assignment2-test.log 2>&1; then
            pass "test.sh passes"
        else
            fail "test.sh reported failures (see /tmp/assignment2-test.log)"
        fi
    else
        fail "docker not available - cannot run test.sh"
    fi
else
    fail "test.sh missing or not executable"
fi

info "Git history"
if [ -d .git ]; then
    COMMIT_COUNT=$(git log --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [ "${COMMIT_COUNT}" -ge 5 ]; then
        pass "at least 5 commits found (${COMMIT_COUNT})"
    else
        fail "fewer than 5 commits found (${COMMIT_COUNT})"
    fi

    if git log --merges --oneline 2>/dev/null | grep -q .; then
        pass "merge commit found in history"
    else
        fail "no merge commit found (feature branch should be merged into main)"
    fi
else
    fail ".git directory not found - is this a git repository?"
fi

echo
echo "=============================="
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "=============================="

if [ "${FAIL}" -gt 0 ]; then
    exit 1
fi
exit 0
