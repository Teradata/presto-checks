#!/usr/bin/env bash

"$@" 2>&1 | awk '/No tests executed/{r=1} END{exit !r} 1'

STATUSES=( ${PIPESTATUS[@]} )

if [[ ${STATUSES[0]} -ne 0 ]] && [[ ${STATUSES[1]} -eq 0 ]]; then
  echo "Overriding exit status"
  STATUS=0
else
  STATUS=${STATUSES[0]}
fi

echo "$0 exiting with $STATUS"
exit $STATUS