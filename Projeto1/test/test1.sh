#!/bin/bash

set -euo pipefail

SUBMISSION_ZIP="${1}"

echo "Checking submission file: $SUBMISSION_ZIP"

if [ ! -f "$SUBMISSION_ZIP" ]; then
  echo FAIL
  exit
fi

echo -ne "Checking file name...\t\t"
if [ "$(basename $SUBMISSION_ZIP)" == "project1.zip" ]; then
  echo OK
else
  echo FAIL
  exit
fi

echo -ne "Checking file type...\t\t"
if [ "$(file -bi $SUBMISSION_ZIP)" == "application/zip; charset=binary" ]; then
  echo OK
else
  echo FAIL exit 
fi

echo "Checking submission contents."

WORK_DIR="$(mktemp -d)"

function cleanup {
  echo "Cleaning up."
  rm -rf "$WORK_DIR"
  killall chat-client 2>/dev/null || true
  killall chat-server 2>/dev/null || true
}
trap cleanup EXIT

cp "$SUBMISSION_ZIP" "$WORK_DIR"
cd "$WORK_DIR"
unzip project1.zip

echo -ne "Checking for Makefile...\t"
if [ -f "Makefile" ]; then
  echo "OK"
else
  echo "FAIL"
  exit
fi

echo "Building project."

make

echo -ne "Checking for chat-client...\t"
if [ -x "chat-client" ]; then
  echo "OK"
else
  echo "FAIL"
  exit
fi

echo -ne "Checking for chat-server...\t"
if [ -x "chat-server" ]; then
  echo "OK"
else
  echo "FAIL"
  exit
fi

echo "Running project."

declare -a clientPids
declare -a IPPorts

./chat-server 4234 >/dev/null 2>/dev/null &
SERVER_PID=$!

(sleep 20) | ./chat-client localhost 4234 > chat-client.out &
RCLIENT_PID=$!
sleep .1
RCLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$RCLIENT_PID/./chat-client\" {print \$4}")

for i in {0..100}
do
    (echo "Test $i"; sleep .3) | ./chat-client localhost 4234 >/dev/null 2>/dev/null &
    clientPids[${i}]=$!
    sleep .1
    IPPorts[${i}]=$(netstat -np 2>/dev/null | awk "\$7 == \"${clientPids[${i}]}/./chat-client\" {print \$4}")
done

#echo ${clientPids[@]}
#echo ${IPPorts[@]}


for i in ${clientPids[@]}
do
    wait ${i} || true
done

kill $SERVER_PID
wait $SERVER_PID 2>/dev/null || true
wait $RCLIENT_PID || true

cat chat-client.out

