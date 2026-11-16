#!/bin/bash
# CI: run after a failed Build step. The step writes $RUNNER_TEMP/build-exit
# when the build ends by itself, so without it the step was stopped at its
# time limit: report that (step output "reached") and create the marker file
# that is uploaded as the timeout-<platform> artifact.
set -euo pipefail
if [ -f "$RUNNER_TEMP/build-exit" ]; then
  echo "The build failed with exit code $(cat "$RUNNER_TEMP/build-exit")"
  exit 0
fi
echo "::warning::The build reached its time limit. Its compiled objects are cached; with sccache it is continued in a new run."
echo "$PLATFORM_KEY" > "$RUNNER_TEMP/time-limit-marker"
echo "reached=true" >> "$GITHUB_OUTPUT"
