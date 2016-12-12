#!/bin/bash

MAGIC_END_STRING="END OF SUBCOMMAND"
OUTPUT_SLEEP=60

function run_command {
  PIPE=$1
  shift
  CMD="$@"
  $CMD 1>$PIPE 2>$PIPE
  echo "$MAGIC_END_STRING" 1>$PIPE
}

function run_ping {
  PIPE=$1
  shift
  CMD="$@"
  (
    while [ 1 ]
    do
      echo "Command '$CMD' is still running."
      sleep $OUTPUT_SLEEP
    done
  ) >$PIPE
}

function presto_wait {
  PIPE=$1
  shift
  CMD="$@"

  mkfifo $PIPE
  echo "Starting command '$CMD' using pipe $PIPE"
  run_command $PIPE $CMD &
  run_ping $PIPE $CMD &
  ping_pid=$!
  
  while read output
  do
    echo $output
    if [ "$output" == "$MAGIC_END_STRING" ]
    then
      rm -f $PIPE
      kill -15 $ping_pid
      exit 0
    fi
  done < $PIPE
}

if [ $# -lt 2 ]
then
  echo "Usage: $0 [PIPE_NAME] [COMMAND]"
  exit 1
fi

trap "kill 0" SIGINT
PIPE="/tmp/command_output_pipe_$( date +%s )"
CMD="$@"
presto_wait $PIPE $CMD
