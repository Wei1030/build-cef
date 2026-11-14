#!/bin/bash
# Prints the sccache statistics and a summary of the errors in the sccache
# server log (SCCACHE_ERROR_LOG, written at the SCCACHE_LOG level set in CI).
sccache --show-stats
log="${SCCACHE_ERROR_LOG:-}"
if [ -n "$log" ] && [ -f "$log" ]; then
  echo
  echo "$log: $(wc -c < "$log") bytes; most frequent errors:"
  # Collapse hashes and numbers so identical errors group together.
  grep -iE "error|fail" "$log" \
    | sed -E 's/^\[[^]]*\] *//; s/[0-9a-f]{16,}/H/g; s/[0-9]+/N/g' \
    | cut -c1-300 | sort | uniq -c | sort -rn | head -30
fi
exit 0
