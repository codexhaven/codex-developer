#!/usr/bin/env bash
# v12.3 Self-Test Pipeline (Silent/Reporting mode)
REPODIR="$(readlink -f "${1:-$HOME/projects}")"
TEST_LOG="${REPODIR}/.codex/test_summary.log"

if [ -d "${REPODIR}/tests" ]; then
    # Run pytest silently, redirect output to a file if it fails
    if ! pytest "${REPODIR}/tests" > /dev/null 2> "${TEST_LOG}"; then
        echo "TEST FAILED. See ${TEST_LOG} for details."
        # Extract only the summary line for the main log
        tail -n 5 "${TEST_LOG}" | grep "=="
    else
        echo "TEST PASSED."
    fi
else
    echo "No tests found in ${REPODIR}/tests"
fi
