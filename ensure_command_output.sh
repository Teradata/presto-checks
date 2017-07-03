#!/bin/bash -e

OUTPUT_SLEEP=60

function print_with_interval {
  message="$1"
  interval="$2"
    while [ 1 ]
    do
      echo $message
      sleep $interval
    done
}

function wait_and_print_ping {
  CMD="$@"

  echo "Starting command '$CMD'"
  $CMD &
  command_pid=$!
  print_with_interval "Command '$CMD' is still running." $OUTPUT_SLEEP &
  print_pid=$!
 
  wait $command_pid
  exit_code=$?
      
  kill -TERM $print_pid
  return $exit_code
}

if [ $# -lt 2 ]
then
  echo "Usage: $0 [COMMAND]"
  exit 1
fi

trap "kill 0" SIGINT
CMD="$@"
wait_and_print_ping $CMD
