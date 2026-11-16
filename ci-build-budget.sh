#!/bin/bash
# CI: prints the minutes the Build step may run (as the step output
# "minutes"), so that it stops BUILD_DEADLINE_MINUTES after the job started
# (JOB_START, epoch seconds) and the job still has time to report and cache.
set -euo pipefail
elapsed=$(( ($(date +%s) - JOB_START) / 60 ))
minutes=$(( BUILD_DEADLINE_MINUTES - elapsed ))
# A minimum of one minute: the build then stops right away and is continued
# by the next run.
[ "$minutes" -ge 1 ] || minutes=1
echo "Job running for ${elapsed} min; the build may run for ${minutes} min"
echo "minutes=$minutes" >> "$GITHUB_OUTPUT"
