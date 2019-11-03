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
  echo FAIL
  exit
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

./chat-server 1234 >/dev/null 2>/dev/null &
SERVER_PID=$!

(sleep .5) | ./chat-client localhost 1234 >chat-client.out 2>/dev/null &
RCLIENT_PID=$!
sleep .1
RCLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$RCLIENT_PID/./chat-client\" {print \$4}")

(echo Test; sleep .3) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
SCLIENT_PID=$!
sleep .1
SCLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$SCLIENT_PID/./chat-client\" {print \$4}")

wait $SCLIENT_PID || true
kill $SERVER_PID
wait $SERVER_PID 2>/dev/null || true
wait $RCLIENT_PID || true

echo -ne "Checking output format...\t"
if diff chat-client.out - <<EOF
$RCLIENT_IPPORT joined.
$SCLIENT_IPPORT joined.
$SCLIENT_IPPORT Test
$SCLIENT_IPPORT left.
EOF
then
  echo OK
else
  echo FAIL
  exit
fi

echo "All basic checks passed."

echo "Starting Warmup test."

./chat-server 1234 >/dev/null 2>/dev/null &
SERVER_PID=$!

(sleep .5) | ./chat-client localhost 1234 >chat-client.out 2>/dev/null &
RCLIENT_PID=$!
sleep .1
RCLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$RCLIENT_PID/./chat-client\" {print \$4}")

(echo Test; sleep .3) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
SCLIENT_PID=$!
sleep .1
SCLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$SCLIENT_PID/./chat-client\" {print \$4}")

(echo Test; sleep .3) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
FCLIENT_PID=$!
sleep .1
FCLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$FCLIENT_PID/./chat-client\" {print \$4}")

wait $SCLIENT_PID || true
kill $SERVER_PID
wait $SERVER_PID 2>/dev/null || true
wait $RCLIENT_PID || true
wait $FCLIENT_PID || true

echo -ne "Checking output format...\t"
if diff chat-client.out - <<EOF
$RCLIENT_IPPORT joined.
$SCLIENT_IPPORT joined.
$SCLIENT_IPPORT Test
$FCLIENT_IPPORT joined.
$FCLIENT_IPPORT Test
$SCLIENT_IPPORT left.
EOF
then
  echo OK
else
  echo FAIL
  exit
fi

echo "Finished Warmup test."

echo "Starting Big String test."

./chat-server 1234 >/dev/null 2>/dev/null &
SERVER_PID=$!

(sleep .5) | ./chat-client localhost 1234 >chat-client.out 2>/dev/null &
RCLIENT_PID=$!
sleep .1
RCLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$RCLIENT_PID/./chat-client\" {print \$4}")

(echo eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee; sleep .3) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
SCLIENT_PID=$!
sleep .1
SCLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$SCLIENT_PID/./chat-client\" {print \$4}")

wait $SCLIENT_PID || true
kill $SERVER_PID
wait $SERVER_PID 2>/dev/null || true
wait $RCLIENT_PID || true

echo -ne "Checking output format...\t"
if diff chat-client.out - <<EOF
$RCLIENT_IPPORT joined.
$SCLIENT_IPPORT joined.
$SCLIENT_IPPORT eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
$SCLIENT_IPPORT left.
EOF
then
  echo OK
else
  echo FAIL
  exit
fi

echo "Finished Big String test."

echo "Starting Big Clients test."

./chat-server 1234 >/dev/null 2>/dev/null &
SERVER_PID=$!

(sleep 999) | ./chat-client localhost 1234 >chat-client.out 2>/dev/null &
RCLIENT_PID=$!
sleep .1
RCLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$RCLIENT_PID/./chat-client\" {print \$4}")

(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_0CLIENT_PID=$!
sleep .1
_0CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_0CLIENT_PID/./chat-client\" {print \$4}")
echo "0.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_1CLIENT_PID=$!
sleep .1
_1CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_1CLIENT_PID/./chat-client\" {print \$4}")
echo "0.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_2CLIENT_PID=$!
sleep .1
_2CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_2CLIENT_PID/./chat-client\" {print \$4}")
echo "0.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_3CLIENT_PID=$!
sleep .1
_3CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_3CLIENT_PID/./chat-client\" {print \$4}")
echo "0.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_4CLIENT_PID=$!
sleep .1
_4CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_4CLIENT_PID/./chat-client\" {print \$4}")
echo "0.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_5CLIENT_PID=$!
sleep .1
_5CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_5CLIENT_PID/./chat-client\" {print \$4}")
echo "0.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_6CLIENT_PID=$!
sleep .1
_6CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_6CLIENT_PID/./chat-client\" {print \$4}")
echo "0.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_7CLIENT_PID=$!
sleep .1
_7CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_7CLIENT_PID/./chat-client\" {print \$4}")
echo "0.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_8CLIENT_PID=$!
sleep .1
_8CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_8CLIENT_PID/./chat-client\" {print \$4}")
echo "0.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_9CLIENT_PID=$!
sleep .1
_9CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_9CLIENT_PID/./chat-client\" {print \$4}")
echo "0.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_10CLIENT_PID=$!
sleep .1
_10CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_10CLIENT_PID/./chat-client\" {print \$4}")
echo "1.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_11CLIENT_PID=$!
sleep .1
_11CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_11CLIENT_PID/./chat-client\" {print \$4}")
echo "1.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_12CLIENT_PID=$!
sleep .1
_12CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_12CLIENT_PID/./chat-client\" {print \$4}")
echo "1.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_13CLIENT_PID=$!
sleep .1
_13CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_13CLIENT_PID/./chat-client\" {print \$4}")
echo "1.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_14CLIENT_PID=$!
sleep .1
_14CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_14CLIENT_PID/./chat-client\" {print \$4}")
echo "1.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_15CLIENT_PID=$!
sleep .1
_15CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_15CLIENT_PID/./chat-client\" {print \$4}")
echo "1.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_16CLIENT_PID=$!
sleep .1
_16CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_16CLIENT_PID/./chat-client\" {print \$4}")
echo "1.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_17CLIENT_PID=$!
sleep .1
_17CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_17CLIENT_PID/./chat-client\" {print \$4}")
echo "1.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_18CLIENT_PID=$!
sleep .1
_18CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_18CLIENT_PID/./chat-client\" {print \$4}")
echo "1.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_19CLIENT_PID=$!
sleep .1
_19CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_19CLIENT_PID/./chat-client\" {print \$4}")
echo "1.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_20CLIENT_PID=$!
sleep .1
_20CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_20CLIENT_PID/./chat-client\" {print \$4}")
echo "2.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_21CLIENT_PID=$!
sleep .1
_21CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_21CLIENT_PID/./chat-client\" {print \$4}")
echo "2.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_22CLIENT_PID=$!
sleep .1
_22CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_22CLIENT_PID/./chat-client\" {print \$4}")
echo "2.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_23CLIENT_PID=$!
sleep .1
_23CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_23CLIENT_PID/./chat-client\" {print \$4}")
echo "2.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_24CLIENT_PID=$!
sleep .1
_24CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_24CLIENT_PID/./chat-client\" {print \$4}")
echo "2.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_25CLIENT_PID=$!
sleep .1
_25CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_25CLIENT_PID/./chat-client\" {print \$4}")
echo "2.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_26CLIENT_PID=$!
sleep .1
_26CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_26CLIENT_PID/./chat-client\" {print \$4}")
echo "2.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_27CLIENT_PID=$!
sleep .1
_27CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_27CLIENT_PID/./chat-client\" {print \$4}")
echo "2.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_28CLIENT_PID=$!
sleep .1
_28CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_28CLIENT_PID/./chat-client\" {print \$4}")
echo "2.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_29CLIENT_PID=$!
sleep .1
_29CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_29CLIENT_PID/./chat-client\" {print \$4}")
echo "2.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_30CLIENT_PID=$!
sleep .1
_30CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_30CLIENT_PID/./chat-client\" {print \$4}")
echo "3.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_31CLIENT_PID=$!
sleep .1
_31CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_31CLIENT_PID/./chat-client\" {print \$4}")
echo "3.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_32CLIENT_PID=$!
sleep .1
_32CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_32CLIENT_PID/./chat-client\" {print \$4}")
echo "3.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_33CLIENT_PID=$!
sleep .1
_33CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_33CLIENT_PID/./chat-client\" {print \$4}")
echo "3.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_34CLIENT_PID=$!
sleep .1
_34CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_34CLIENT_PID/./chat-client\" {print \$4}")
echo "3.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_35CLIENT_PID=$!
sleep .1
_35CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_35CLIENT_PID/./chat-client\" {print \$4}")
echo "3.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_36CLIENT_PID=$!
sleep .1
_36CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_36CLIENT_PID/./chat-client\" {print \$4}")
echo "3.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_37CLIENT_PID=$!
sleep .1
_37CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_37CLIENT_PID/./chat-client\" {print \$4}")
echo "3.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_38CLIENT_PID=$!
sleep .1
_38CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_38CLIENT_PID/./chat-client\" {print \$4}")
echo "3.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_39CLIENT_PID=$!
sleep .1
_39CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_39CLIENT_PID/./chat-client\" {print \$4}")
echo "3.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_40CLIENT_PID=$!
sleep .1
_40CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_40CLIENT_PID/./chat-client\" {print \$4}")
echo "4.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_41CLIENT_PID=$!
sleep .1
_41CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_41CLIENT_PID/./chat-client\" {print \$4}")
echo "4.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_42CLIENT_PID=$!
sleep .1
_42CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_42CLIENT_PID/./chat-client\" {print \$4}")
echo "4.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_43CLIENT_PID=$!
sleep .1
_43CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_43CLIENT_PID/./chat-client\" {print \$4}")
echo "4.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_44CLIENT_PID=$!
sleep .1
_44CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_44CLIENT_PID/./chat-client\" {print \$4}")
echo "4.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_45CLIENT_PID=$!
sleep .1
_45CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_45CLIENT_PID/./chat-client\" {print \$4}")
echo "4.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_46CLIENT_PID=$!
sleep .1
_46CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_46CLIENT_PID/./chat-client\" {print \$4}")
echo "4.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_47CLIENT_PID=$!
sleep .1
_47CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_47CLIENT_PID/./chat-client\" {print \$4}")
echo "4.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_48CLIENT_PID=$!
sleep .1
_48CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_48CLIENT_PID/./chat-client\" {print \$4}")
echo "4.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_49CLIENT_PID=$!
sleep .1
_49CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_49CLIENT_PID/./chat-client\" {print \$4}")
echo "4.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_50CLIENT_PID=$!
sleep .1
_50CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_50CLIENT_PID/./chat-client\" {print \$4}")
echo "5.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_51CLIENT_PID=$!
sleep .1
_51CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_51CLIENT_PID/./chat-client\" {print \$4}")
echo "5.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_52CLIENT_PID=$!
sleep .1
_52CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_52CLIENT_PID/./chat-client\" {print \$4}")
echo "5.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_53CLIENT_PID=$!
sleep .1
_53CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_53CLIENT_PID/./chat-client\" {print \$4}")
echo "5.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_54CLIENT_PID=$!
sleep .1
_54CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_54CLIENT_PID/./chat-client\" {print \$4}")
echo "5.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_55CLIENT_PID=$!
sleep .1
_55CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_55CLIENT_PID/./chat-client\" {print \$4}")
echo "5.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_56CLIENT_PID=$!
sleep .1
_56CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_56CLIENT_PID/./chat-client\" {print \$4}")
echo "5.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_57CLIENT_PID=$!
sleep .1
_57CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_57CLIENT_PID/./chat-client\" {print \$4}")
echo "5.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_58CLIENT_PID=$!
sleep .1
_58CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_58CLIENT_PID/./chat-client\" {print \$4}")
echo "5.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_59CLIENT_PID=$!
sleep .1
_59CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_59CLIENT_PID/./chat-client\" {print \$4}")
echo "5.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_60CLIENT_PID=$!
sleep .1
_60CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_60CLIENT_PID/./chat-client\" {print \$4}")
echo "6.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_61CLIENT_PID=$!
sleep .1
_61CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_61CLIENT_PID/./chat-client\" {print \$4}")
echo "6.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_62CLIENT_PID=$!
sleep .1
_62CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_62CLIENT_PID/./chat-client\" {print \$4}")
echo "6.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_63CLIENT_PID=$!
sleep .1
_63CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_63CLIENT_PID/./chat-client\" {print \$4}")
echo "6.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_64CLIENT_PID=$!
sleep .1
_64CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_64CLIENT_PID/./chat-client\" {print \$4}")
echo "6.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_65CLIENT_PID=$!
sleep .1
_65CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_65CLIENT_PID/./chat-client\" {print \$4}")
echo "6.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_66CLIENT_PID=$!
sleep .1
_66CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_66CLIENT_PID/./chat-client\" {print \$4}")
echo "6.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_67CLIENT_PID=$!
sleep .1
_67CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_67CLIENT_PID/./chat-client\" {print \$4}")
echo "6.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_68CLIENT_PID=$!
sleep .1
_68CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_68CLIENT_PID/./chat-client\" {print \$4}")
echo "6.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_69CLIENT_PID=$!
sleep .1
_69CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_69CLIENT_PID/./chat-client\" {print \$4}")
echo "6.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_70CLIENT_PID=$!
sleep .1
_70CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_70CLIENT_PID/./chat-client\" {print \$4}")
echo "7.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_71CLIENT_PID=$!
sleep .1
_71CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_71CLIENT_PID/./chat-client\" {print \$4}")
echo "7.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_72CLIENT_PID=$!
sleep .1
_72CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_72CLIENT_PID/./chat-client\" {print \$4}")
echo "7.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_73CLIENT_PID=$!
sleep .1
_73CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_73CLIENT_PID/./chat-client\" {print \$4}")
echo "7.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_74CLIENT_PID=$!
sleep .1
_74CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_74CLIENT_PID/./chat-client\" {print \$4}")
echo "7.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_75CLIENT_PID=$!
sleep .1
_75CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_75CLIENT_PID/./chat-client\" {print \$4}")
echo "7.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_76CLIENT_PID=$!
sleep .1
_76CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_76CLIENT_PID/./chat-client\" {print \$4}")
echo "7.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_77CLIENT_PID=$!
sleep .1
_77CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_77CLIENT_PID/./chat-client\" {print \$4}")
echo "7.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_78CLIENT_PID=$!
sleep .1
_78CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_78CLIENT_PID/./chat-client\" {print \$4}")
echo "7.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_79CLIENT_PID=$!
sleep .1
_79CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_79CLIENT_PID/./chat-client\" {print \$4}")
echo "7.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_80CLIENT_PID=$!
sleep .1
_80CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_80CLIENT_PID/./chat-client\" {print \$4}")
echo "8.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_81CLIENT_PID=$!
sleep .1
_81CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_81CLIENT_PID/./chat-client\" {print \$4}")
echo "8.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_82CLIENT_PID=$!
sleep .1
_82CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_82CLIENT_PID/./chat-client\" {print \$4}")
echo "8.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_83CLIENT_PID=$!
sleep .1
_83CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_83CLIENT_PID/./chat-client\" {print \$4}")
echo "8.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_84CLIENT_PID=$!
sleep .1
_84CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_84CLIENT_PID/./chat-client\" {print \$4}")
echo "8.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_85CLIENT_PID=$!
sleep .1
_85CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_85CLIENT_PID/./chat-client\" {print \$4}")
echo "8.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_86CLIENT_PID=$!
sleep .1
_86CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_86CLIENT_PID/./chat-client\" {print \$4}")
echo "8.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_87CLIENT_PID=$!
sleep .1
_87CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_87CLIENT_PID/./chat-client\" {print \$4}")
echo "8.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_88CLIENT_PID=$!
sleep .1
_88CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_88CLIENT_PID/./chat-client\" {print \$4}")
echo "8.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_89CLIENT_PID=$!
sleep .1
_89CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_89CLIENT_PID/./chat-client\" {print \$4}")
echo "8.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_90CLIENT_PID=$!
sleep .1
_90CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_90CLIENT_PID/./chat-client\" {print \$4}")
echo "9.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_91CLIENT_PID=$!
sleep .1
_91CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_91CLIENT_PID/./chat-client\" {print \$4}")
echo "9.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_92CLIENT_PID=$!
sleep .1
_92CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_92CLIENT_PID/./chat-client\" {print \$4}")
echo "9.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_93CLIENT_PID=$!
sleep .1
_93CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_93CLIENT_PID/./chat-client\" {print \$4}")
echo "9.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_94CLIENT_PID=$!
sleep .1
_94CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_94CLIENT_PID/./chat-client\" {print \$4}")
echo "9.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_95CLIENT_PID=$!
sleep .1
_95CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_95CLIENT_PID/./chat-client\" {print \$4}")
echo "9.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_96CLIENT_PID=$!
sleep .1
_96CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_96CLIENT_PID/./chat-client\" {print \$4}")
echo "9.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_97CLIENT_PID=$!
sleep .1
_97CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_97CLIENT_PID/./chat-client\" {print \$4}")
echo "9.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_98CLIENT_PID=$!
sleep .1
_98CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_98CLIENT_PID/./chat-client\" {print \$4}")
echo "9.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_99CLIENT_PID=$!
sleep .1
_99CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_99CLIENT_PID/./chat-client\" {print \$4}")
echo "9.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_100CLIENT_PID=$!
sleep .1
_100CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_100CLIENT_PID/./chat-client\" {print \$4}")
echo "10.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_101CLIENT_PID=$!
sleep .1
_101CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_101CLIENT_PID/./chat-client\" {print \$4}")
echo "10.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_102CLIENT_PID=$!
sleep .1
_102CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_102CLIENT_PID/./chat-client\" {print \$4}")
echo "10.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_103CLIENT_PID=$!
sleep .1
_103CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_103CLIENT_PID/./chat-client\" {print \$4}")
echo "10.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_104CLIENT_PID=$!
sleep .1
_104CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_104CLIENT_PID/./chat-client\" {print \$4}")
echo "10.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_105CLIENT_PID=$!
sleep .1
_105CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_105CLIENT_PID/./chat-client\" {print \$4}")
echo "10.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_106CLIENT_PID=$!
sleep .1
_106CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_106CLIENT_PID/./chat-client\" {print \$4}")
echo "10.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_107CLIENT_PID=$!
sleep .1
_107CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_107CLIENT_PID/./chat-client\" {print \$4}")
echo "10.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_108CLIENT_PID=$!
sleep .1
_108CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_108CLIENT_PID/./chat-client\" {print \$4}")
echo "10.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_109CLIENT_PID=$!
sleep .1
_109CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_109CLIENT_PID/./chat-client\" {print \$4}")
echo "10.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_110CLIENT_PID=$!
sleep .1
_110CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_110CLIENT_PID/./chat-client\" {print \$4}")
echo "11.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_111CLIENT_PID=$!
sleep .1
_111CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_111CLIENT_PID/./chat-client\" {print \$4}")
echo "11.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_112CLIENT_PID=$!
sleep .1
_112CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_112CLIENT_PID/./chat-client\" {print \$4}")
echo "11.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_113CLIENT_PID=$!
sleep .1
_113CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_113CLIENT_PID/./chat-client\" {print \$4}")
echo "11.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_114CLIENT_PID=$!
sleep .1
_114CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_114CLIENT_PID/./chat-client\" {print \$4}")
echo "11.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_115CLIENT_PID=$!
sleep .1
_115CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_115CLIENT_PID/./chat-client\" {print \$4}")
echo "11.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_116CLIENT_PID=$!
sleep .1
_116CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_116CLIENT_PID/./chat-client\" {print \$4}")
echo "11.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_117CLIENT_PID=$!
sleep .1
_117CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_117CLIENT_PID/./chat-client\" {print \$4}")
echo "11.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_118CLIENT_PID=$!
sleep .1
_118CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_118CLIENT_PID/./chat-client\" {print \$4}")
echo "11.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_119CLIENT_PID=$!
sleep .1
_119CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_119CLIENT_PID/./chat-client\" {print \$4}")
echo "11.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_120CLIENT_PID=$!
sleep .1
_120CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_120CLIENT_PID/./chat-client\" {print \$4}")
echo "12.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_121CLIENT_PID=$!
sleep .1
_121CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_121CLIENT_PID/./chat-client\" {print \$4}")
echo "12.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_122CLIENT_PID=$!
sleep .1
_122CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_122CLIENT_PID/./chat-client\" {print \$4}")
echo "12.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_123CLIENT_PID=$!
sleep .1
_123CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_123CLIENT_PID/./chat-client\" {print \$4}")
echo "12.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_124CLIENT_PID=$!
sleep .1
_124CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_124CLIENT_PID/./chat-client\" {print \$4}")
echo "12.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_125CLIENT_PID=$!
sleep .1
_125CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_125CLIENT_PID/./chat-client\" {print \$4}")
echo "12.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_126CLIENT_PID=$!
sleep .1
_126CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_126CLIENT_PID/./chat-client\" {print \$4}")
echo "12.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_127CLIENT_PID=$!
sleep .1
_127CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_127CLIENT_PID/./chat-client\" {print \$4}")
echo "12.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_128CLIENT_PID=$!
sleep .1
_128CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_128CLIENT_PID/./chat-client\" {print \$4}")
echo "12.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_129CLIENT_PID=$!
sleep .1
_129CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_129CLIENT_PID/./chat-client\" {print \$4}")
echo "12.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_130CLIENT_PID=$!
sleep .1
_130CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_130CLIENT_PID/./chat-client\" {print \$4}")
echo "13.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_131CLIENT_PID=$!
sleep .1
_131CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_131CLIENT_PID/./chat-client\" {print \$4}")
echo "13.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_132CLIENT_PID=$!
sleep .1
_132CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_132CLIENT_PID/./chat-client\" {print \$4}")
echo "13.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_133CLIENT_PID=$!
sleep .1
_133CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_133CLIENT_PID/./chat-client\" {print \$4}")
echo "13.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_134CLIENT_PID=$!
sleep .1
_134CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_134CLIENT_PID/./chat-client\" {print \$4}")
echo "13.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_135CLIENT_PID=$!
sleep .1
_135CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_135CLIENT_PID/./chat-client\" {print \$4}")
echo "13.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_136CLIENT_PID=$!
sleep .1
_136CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_136CLIENT_PID/./chat-client\" {print \$4}")
echo "13.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_137CLIENT_PID=$!
sleep .1
_137CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_137CLIENT_PID/./chat-client\" {print \$4}")
echo "13.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_138CLIENT_PID=$!
sleep .1
_138CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_138CLIENT_PID/./chat-client\" {print \$4}")
echo "13.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_139CLIENT_PID=$!
sleep .1
_139CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_139CLIENT_PID/./chat-client\" {print \$4}")
echo "13.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_140CLIENT_PID=$!
sleep .1
_140CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_140CLIENT_PID/./chat-client\" {print \$4}")
echo "14.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_141CLIENT_PID=$!
sleep .1
_141CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_141CLIENT_PID/./chat-client\" {print \$4}")
echo "14.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_142CLIENT_PID=$!
sleep .1
_142CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_142CLIENT_PID/./chat-client\" {print \$4}")
echo "14.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_143CLIENT_PID=$!
sleep .1
_143CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_143CLIENT_PID/./chat-client\" {print \$4}")
echo "14.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_144CLIENT_PID=$!
sleep .1
_144CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_144CLIENT_PID/./chat-client\" {print \$4}")
echo "14.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_145CLIENT_PID=$!
sleep .1
_145CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_145CLIENT_PID/./chat-client\" {print \$4}")
echo "14.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_146CLIENT_PID=$!
sleep .1
_146CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_146CLIENT_PID/./chat-client\" {print \$4}")
echo "14.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_147CLIENT_PID=$!
sleep .1
_147CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_147CLIENT_PID/./chat-client\" {print \$4}")
echo "14.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_148CLIENT_PID=$!
sleep .1
_148CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_148CLIENT_PID/./chat-client\" {print \$4}")
echo "14.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_149CLIENT_PID=$!
sleep .1
_149CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_149CLIENT_PID/./chat-client\" {print \$4}")
echo "14.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_150CLIENT_PID=$!
sleep .1
_150CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_150CLIENT_PID/./chat-client\" {print \$4}")
echo "15.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_151CLIENT_PID=$!
sleep .1
_151CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_151CLIENT_PID/./chat-client\" {print \$4}")
echo "15.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_152CLIENT_PID=$!
sleep .1
_152CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_152CLIENT_PID/./chat-client\" {print \$4}")
echo "15.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_153CLIENT_PID=$!
sleep .1
_153CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_153CLIENT_PID/./chat-client\" {print \$4}")
echo "15.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_154CLIENT_PID=$!
sleep .1
_154CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_154CLIENT_PID/./chat-client\" {print \$4}")
echo "15.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_155CLIENT_PID=$!
sleep .1
_155CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_155CLIENT_PID/./chat-client\" {print \$4}")
echo "15.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_156CLIENT_PID=$!
sleep .1
_156CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_156CLIENT_PID/./chat-client\" {print \$4}")
echo "15.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_157CLIENT_PID=$!
sleep .1
_157CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_157CLIENT_PID/./chat-client\" {print \$4}")
echo "15.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_158CLIENT_PID=$!
sleep .1
_158CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_158CLIENT_PID/./chat-client\" {print \$4}")
echo "15.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_159CLIENT_PID=$!
sleep .1
_159CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_159CLIENT_PID/./chat-client\" {print \$4}")
echo "15.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_160CLIENT_PID=$!
sleep .1
_160CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_160CLIENT_PID/./chat-client\" {print \$4}")
echo "16.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_161CLIENT_PID=$!
sleep .1
_161CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_161CLIENT_PID/./chat-client\" {print \$4}")
echo "16.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_162CLIENT_PID=$!
sleep .1
_162CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_162CLIENT_PID/./chat-client\" {print \$4}")
echo "16.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_163CLIENT_PID=$!
sleep .1
_163CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_163CLIENT_PID/./chat-client\" {print \$4}")
echo "16.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_164CLIENT_PID=$!
sleep .1
_164CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_164CLIENT_PID/./chat-client\" {print \$4}")
echo "16.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_165CLIENT_PID=$!
sleep .1
_165CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_165CLIENT_PID/./chat-client\" {print \$4}")
echo "16.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_166CLIENT_PID=$!
sleep .1
_166CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_166CLIENT_PID/./chat-client\" {print \$4}")
echo "16.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_167CLIENT_PID=$!
sleep .1
_167CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_167CLIENT_PID/./chat-client\" {print \$4}")
echo "16.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_168CLIENT_PID=$!
sleep .1
_168CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_168CLIENT_PID/./chat-client\" {print \$4}")
echo "16.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_169CLIENT_PID=$!
sleep .1
_169CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_169CLIENT_PID/./chat-client\" {print \$4}")
echo "16.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_170CLIENT_PID=$!
sleep .1
_170CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_170CLIENT_PID/./chat-client\" {print \$4}")
echo "17.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_171CLIENT_PID=$!
sleep .1
_171CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_171CLIENT_PID/./chat-client\" {print \$4}")
echo "17.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_172CLIENT_PID=$!
sleep .1
_172CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_172CLIENT_PID/./chat-client\" {print \$4}")
echo "17.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_173CLIENT_PID=$!
sleep .1
_173CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_173CLIENT_PID/./chat-client\" {print \$4}")
echo "17.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_174CLIENT_PID=$!
sleep .1
_174CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_174CLIENT_PID/./chat-client\" {print \$4}")
echo "17.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_175CLIENT_PID=$!
sleep .1
_175CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_175CLIENT_PID/./chat-client\" {print \$4}")
echo "17.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_176CLIENT_PID=$!
sleep .1
_176CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_176CLIENT_PID/./chat-client\" {print \$4}")
echo "17.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_177CLIENT_PID=$!
sleep .1
_177CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_177CLIENT_PID/./chat-client\" {print \$4}")
echo "17.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_178CLIENT_PID=$!
sleep .1
_178CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_178CLIENT_PID/./chat-client\" {print \$4}")
echo "17.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_179CLIENT_PID=$!
sleep .1
_179CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_179CLIENT_PID/./chat-client\" {print \$4}")
echo "17.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_180CLIENT_PID=$!
sleep .1
_180CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_180CLIENT_PID/./chat-client\" {print \$4}")
echo "18.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_181CLIENT_PID=$!
sleep .1
_181CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_181CLIENT_PID/./chat-client\" {print \$4}")
echo "18.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_182CLIENT_PID=$!
sleep .1
_182CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_182CLIENT_PID/./chat-client\" {print \$4}")
echo "18.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_183CLIENT_PID=$!
sleep .1
_183CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_183CLIENT_PID/./chat-client\" {print \$4}")
echo "18.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_184CLIENT_PID=$!
sleep .1
_184CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_184CLIENT_PID/./chat-client\" {print \$4}")
echo "18.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_185CLIENT_PID=$!
sleep .1
_185CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_185CLIENT_PID/./chat-client\" {print \$4}")
echo "18.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_186CLIENT_PID=$!
sleep .1
_186CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_186CLIENT_PID/./chat-client\" {print \$4}")
echo "18.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_187CLIENT_PID=$!
sleep .1
_187CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_187CLIENT_PID/./chat-client\" {print \$4}")
echo "18.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_188CLIENT_PID=$!
sleep .1
_188CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_188CLIENT_PID/./chat-client\" {print \$4}")
echo "18.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_189CLIENT_PID=$!
sleep .1
_189CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_189CLIENT_PID/./chat-client\" {print \$4}")
echo "18.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_190CLIENT_PID=$!
sleep .1
_190CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_190CLIENT_PID/./chat-client\" {print \$4}")
echo "19.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_191CLIENT_PID=$!
sleep .1
_191CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_191CLIENT_PID/./chat-client\" {print \$4}")
echo "19.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_192CLIENT_PID=$!
sleep .1
_192CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_192CLIENT_PID/./chat-client\" {print \$4}")
echo "19.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_193CLIENT_PID=$!
sleep .1
_193CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_193CLIENT_PID/./chat-client\" {print \$4}")
echo "19.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_194CLIENT_PID=$!
sleep .1
_194CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_194CLIENT_PID/./chat-client\" {print \$4}")
echo "19.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_195CLIENT_PID=$!
sleep .1
_195CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_195CLIENT_PID/./chat-client\" {print \$4}")
echo "19.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_196CLIENT_PID=$!
sleep .1
_196CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_196CLIENT_PID/./chat-client\" {print \$4}")
echo "19.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_197CLIENT_PID=$!
sleep .1
_197CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_197CLIENT_PID/./chat-client\" {print \$4}")
echo "19.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_198CLIENT_PID=$!
sleep .1
_198CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_198CLIENT_PID/./chat-client\" {print \$4}")
echo "19.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_199CLIENT_PID=$!
sleep .1
_199CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_199CLIENT_PID/./chat-client\" {print \$4}")
echo "19.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_200CLIENT_PID=$!
sleep .1
_200CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_200CLIENT_PID/./chat-client\" {print \$4}")
echo "20.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_201CLIENT_PID=$!
sleep .1
_201CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_201CLIENT_PID/./chat-client\" {print \$4}")
echo "20.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_202CLIENT_PID=$!
sleep .1
_202CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_202CLIENT_PID/./chat-client\" {print \$4}")
echo "20.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_203CLIENT_PID=$!
sleep .1
_203CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_203CLIENT_PID/./chat-client\" {print \$4}")
echo "20.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_204CLIENT_PID=$!
sleep .1
_204CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_204CLIENT_PID/./chat-client\" {print \$4}")
echo "20.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_205CLIENT_PID=$!
sleep .1
_205CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_205CLIENT_PID/./chat-client\" {print \$4}")
echo "20.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_206CLIENT_PID=$!
sleep .1
_206CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_206CLIENT_PID/./chat-client\" {print \$4}")
echo "20.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_207CLIENT_PID=$!
sleep .1
_207CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_207CLIENT_PID/./chat-client\" {print \$4}")
echo "20.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_208CLIENT_PID=$!
sleep .1
_208CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_208CLIENT_PID/./chat-client\" {print \$4}")
echo "20.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_209CLIENT_PID=$!
sleep .1
_209CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_209CLIENT_PID/./chat-client\" {print \$4}")
echo "20.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_210CLIENT_PID=$!
sleep .1
_210CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_210CLIENT_PID/./chat-client\" {print \$4}")
echo "21.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_211CLIENT_PID=$!
sleep .1
_211CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_211CLIENT_PID/./chat-client\" {print \$4}")
echo "21.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_212CLIENT_PID=$!
sleep .1
_212CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_212CLIENT_PID/./chat-client\" {print \$4}")
echo "21.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_213CLIENT_PID=$!
sleep .1
_213CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_213CLIENT_PID/./chat-client\" {print \$4}")
echo "21.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_214CLIENT_PID=$!
sleep .1
_214CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_214CLIENT_PID/./chat-client\" {print \$4}")
echo "21.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_215CLIENT_PID=$!
sleep .1
_215CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_215CLIENT_PID/./chat-client\" {print \$4}")
echo "21.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_216CLIENT_PID=$!
sleep .1
_216CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_216CLIENT_PID/./chat-client\" {print \$4}")
echo "21.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_217CLIENT_PID=$!
sleep .1
_217CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_217CLIENT_PID/./chat-client\" {print \$4}")
echo "21.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_218CLIENT_PID=$!
sleep .1
_218CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_218CLIENT_PID/./chat-client\" {print \$4}")
echo "21.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_219CLIENT_PID=$!
sleep .1
_219CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_219CLIENT_PID/./chat-client\" {print \$4}")
echo "21.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_220CLIENT_PID=$!
sleep .1
_220CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_220CLIENT_PID/./chat-client\" {print \$4}")
echo "22.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_221CLIENT_PID=$!
sleep .1
_221CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_221CLIENT_PID/./chat-client\" {print \$4}")
echo "22.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_222CLIENT_PID=$!
sleep .1
_222CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_222CLIENT_PID/./chat-client\" {print \$4}")
echo "22.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_223CLIENT_PID=$!
sleep .1
_223CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_223CLIENT_PID/./chat-client\" {print \$4}")
echo "22.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_224CLIENT_PID=$!
sleep .1
_224CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_224CLIENT_PID/./chat-client\" {print \$4}")
echo "22.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_225CLIENT_PID=$!
sleep .1
_225CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_225CLIENT_PID/./chat-client\" {print \$4}")
echo "22.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_226CLIENT_PID=$!
sleep .1
_226CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_226CLIENT_PID/./chat-client\" {print \$4}")
echo "22.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_227CLIENT_PID=$!
sleep .1
_227CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_227CLIENT_PID/./chat-client\" {print \$4}")
echo "22.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_228CLIENT_PID=$!
sleep .1
_228CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_228CLIENT_PID/./chat-client\" {print \$4}")
echo "22.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_229CLIENT_PID=$!
sleep .1
_229CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_229CLIENT_PID/./chat-client\" {print \$4}")
echo "22.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_230CLIENT_PID=$!
sleep .1
_230CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_230CLIENT_PID/./chat-client\" {print \$4}")
echo "23.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_231CLIENT_PID=$!
sleep .1
_231CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_231CLIENT_PID/./chat-client\" {print \$4}")
echo "23.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_232CLIENT_PID=$!
sleep .1
_232CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_232CLIENT_PID/./chat-client\" {print \$4}")
echo "23.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_233CLIENT_PID=$!
sleep .1
_233CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_233CLIENT_PID/./chat-client\" {print \$4}")
echo "23.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_234CLIENT_PID=$!
sleep .1
_234CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_234CLIENT_PID/./chat-client\" {print \$4}")
echo "23.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_235CLIENT_PID=$!
sleep .1
_235CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_235CLIENT_PID/./chat-client\" {print \$4}")
echo "23.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_236CLIENT_PID=$!
sleep .1
_236CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_236CLIENT_PID/./chat-client\" {print \$4}")
echo "23.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_237CLIENT_PID=$!
sleep .1
_237CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_237CLIENT_PID/./chat-client\" {print \$4}")
echo "23.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_238CLIENT_PID=$!
sleep .1
_238CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_238CLIENT_PID/./chat-client\" {print \$4}")
echo "23.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_239CLIENT_PID=$!
sleep .1
_239CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_239CLIENT_PID/./chat-client\" {print \$4}")
echo "23.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_240CLIENT_PID=$!
sleep .1
_240CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_240CLIENT_PID/./chat-client\" {print \$4}")
echo "24.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_241CLIENT_PID=$!
sleep .1
_241CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_241CLIENT_PID/./chat-client\" {print \$4}")
echo "24.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_242CLIENT_PID=$!
sleep .1
_242CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_242CLIENT_PID/./chat-client\" {print \$4}")
echo "24.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_243CLIENT_PID=$!
sleep .1
_243CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_243CLIENT_PID/./chat-client\" {print \$4}")
echo "24.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_244CLIENT_PID=$!
sleep .1
_244CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_244CLIENT_PID/./chat-client\" {print \$4}")
echo "24.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_245CLIENT_PID=$!
sleep .1
_245CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_245CLIENT_PID/./chat-client\" {print \$4}")
echo "24.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_246CLIENT_PID=$!
sleep .1
_246CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_246CLIENT_PID/./chat-client\" {print \$4}")
echo "24.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_247CLIENT_PID=$!
sleep .1
_247CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_247CLIENT_PID/./chat-client\" {print \$4}")
echo "24.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_248CLIENT_PID=$!
sleep .1
_248CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_248CLIENT_PID/./chat-client\" {print \$4}")
echo "24.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_249CLIENT_PID=$!
sleep .1
_249CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_249CLIENT_PID/./chat-client\" {print \$4}")
echo "24.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_250CLIENT_PID=$!
sleep .1
_250CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_250CLIENT_PID/./chat-client\" {print \$4}")
echo "25.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_251CLIENT_PID=$!
sleep .1
_251CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_251CLIENT_PID/./chat-client\" {print \$4}")
echo "25.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_252CLIENT_PID=$!
sleep .1
_252CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_252CLIENT_PID/./chat-client\" {print \$4}")
echo "25.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_253CLIENT_PID=$!
sleep .1
_253CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_253CLIENT_PID/./chat-client\" {print \$4}")
echo "25.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_254CLIENT_PID=$!
sleep .1
_254CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_254CLIENT_PID/./chat-client\" {print \$4}")
echo "25.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_255CLIENT_PID=$!
sleep .1
_255CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_255CLIENT_PID/./chat-client\" {print \$4}")
echo "25.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_256CLIENT_PID=$!
sleep .1
_256CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_256CLIENT_PID/./chat-client\" {print \$4}")
echo "25.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_257CLIENT_PID=$!
sleep .1
_257CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_257CLIENT_PID/./chat-client\" {print \$4}")
echo "25.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_258CLIENT_PID=$!
sleep .1
_258CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_258CLIENT_PID/./chat-client\" {print \$4}")
echo "25.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_259CLIENT_PID=$!
sleep .1
_259CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_259CLIENT_PID/./chat-client\" {print \$4}")
echo "25.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_260CLIENT_PID=$!
sleep .1
_260CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_260CLIENT_PID/./chat-client\" {print \$4}")
echo "26.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_261CLIENT_PID=$!
sleep .1
_261CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_261CLIENT_PID/./chat-client\" {print \$4}")
echo "26.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_262CLIENT_PID=$!
sleep .1
_262CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_262CLIENT_PID/./chat-client\" {print \$4}")
echo "26.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_263CLIENT_PID=$!
sleep .1
_263CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_263CLIENT_PID/./chat-client\" {print \$4}")
echo "26.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_264CLIENT_PID=$!
sleep .1
_264CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_264CLIENT_PID/./chat-client\" {print \$4}")
echo "26.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_265CLIENT_PID=$!
sleep .1
_265CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_265CLIENT_PID/./chat-client\" {print \$4}")
echo "26.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_266CLIENT_PID=$!
sleep .1
_266CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_266CLIENT_PID/./chat-client\" {print \$4}")
echo "26.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_267CLIENT_PID=$!
sleep .1
_267CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_267CLIENT_PID/./chat-client\" {print \$4}")
echo "26.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_268CLIENT_PID=$!
sleep .1
_268CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_268CLIENT_PID/./chat-client\" {print \$4}")
echo "26.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_269CLIENT_PID=$!
sleep .1
_269CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_269CLIENT_PID/./chat-client\" {print \$4}")
echo "26.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_270CLIENT_PID=$!
sleep .1
_270CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_270CLIENT_PID/./chat-client\" {print \$4}")
echo "27.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_271CLIENT_PID=$!
sleep .1
_271CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_271CLIENT_PID/./chat-client\" {print \$4}")
echo "27.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_272CLIENT_PID=$!
sleep .1
_272CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_272CLIENT_PID/./chat-client\" {print \$4}")
echo "27.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_273CLIENT_PID=$!
sleep .1
_273CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_273CLIENT_PID/./chat-client\" {print \$4}")
echo "27.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_274CLIENT_PID=$!
sleep .1
_274CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_274CLIENT_PID/./chat-client\" {print \$4}")
echo "27.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_275CLIENT_PID=$!
sleep .1
_275CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_275CLIENT_PID/./chat-client\" {print \$4}")
echo "27.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_276CLIENT_PID=$!
sleep .1
_276CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_276CLIENT_PID/./chat-client\" {print \$4}")
echo "27.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_277CLIENT_PID=$!
sleep .1
_277CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_277CLIENT_PID/./chat-client\" {print \$4}")
echo "27.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_278CLIENT_PID=$!
sleep .1
_278CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_278CLIENT_PID/./chat-client\" {print \$4}")
echo "27.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_279CLIENT_PID=$!
sleep .1
_279CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_279CLIENT_PID/./chat-client\" {print \$4}")
echo "27.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_280CLIENT_PID=$!
sleep .1
_280CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_280CLIENT_PID/./chat-client\" {print \$4}")
echo "28.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_281CLIENT_PID=$!
sleep .1
_281CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_281CLIENT_PID/./chat-client\" {print \$4}")
echo "28.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_282CLIENT_PID=$!
sleep .1
_282CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_282CLIENT_PID/./chat-client\" {print \$4}")
echo "28.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_283CLIENT_PID=$!
sleep .1
_283CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_283CLIENT_PID/./chat-client\" {print \$4}")
echo "28.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_284CLIENT_PID=$!
sleep .1
_284CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_284CLIENT_PID/./chat-client\" {print \$4}")
echo "28.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_285CLIENT_PID=$!
sleep .1
_285CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_285CLIENT_PID/./chat-client\" {print \$4}")
echo "28.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_286CLIENT_PID=$!
sleep .1
_286CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_286CLIENT_PID/./chat-client\" {print \$4}")
echo "28.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_287CLIENT_PID=$!
sleep .1
_287CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_287CLIENT_PID/./chat-client\" {print \$4}")
echo "28.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_288CLIENT_PID=$!
sleep .1
_288CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_288CLIENT_PID/./chat-client\" {print \$4}")
echo "28.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_289CLIENT_PID=$!
sleep .1
_289CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_289CLIENT_PID/./chat-client\" {print \$4}")
echo "28.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_290CLIENT_PID=$!
sleep .1
_290CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_290CLIENT_PID/./chat-client\" {print \$4}")
echo "29.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_291CLIENT_PID=$!
sleep .1
_291CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_291CLIENT_PID/./chat-client\" {print \$4}")
echo "29.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_292CLIENT_PID=$!
sleep .1
_292CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_292CLIENT_PID/./chat-client\" {print \$4}")
echo "29.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_293CLIENT_PID=$!
sleep .1
_293CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_293CLIENT_PID/./chat-client\" {print \$4}")
echo "29.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_294CLIENT_PID=$!
sleep .1
_294CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_294CLIENT_PID/./chat-client\" {print \$4}")
echo "29.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_295CLIENT_PID=$!
sleep .1
_295CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_295CLIENT_PID/./chat-client\" {print \$4}")
echo "29.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_296CLIENT_PID=$!
sleep .1
_296CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_296CLIENT_PID/./chat-client\" {print \$4}")
echo "29.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_297CLIENT_PID=$!
sleep .1
_297CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_297CLIENT_PID/./chat-client\" {print \$4}")
echo "29.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_298CLIENT_PID=$!
sleep .1
_298CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_298CLIENT_PID/./chat-client\" {print \$4}")
echo "29.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_299CLIENT_PID=$!
sleep .1
_299CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_299CLIENT_PID/./chat-client\" {print \$4}")
echo "29.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_300CLIENT_PID=$!
sleep .1
_300CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_300CLIENT_PID/./chat-client\" {print \$4}")
echo "30.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_301CLIENT_PID=$!
sleep .1
_301CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_301CLIENT_PID/./chat-client\" {print \$4}")
echo "30.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_302CLIENT_PID=$!
sleep .1
_302CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_302CLIENT_PID/./chat-client\" {print \$4}")
echo "30.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_303CLIENT_PID=$!
sleep .1
_303CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_303CLIENT_PID/./chat-client\" {print \$4}")
echo "30.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_304CLIENT_PID=$!
sleep .1
_304CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_304CLIENT_PID/./chat-client\" {print \$4}")
echo "30.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_305CLIENT_PID=$!
sleep .1
_305CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_305CLIENT_PID/./chat-client\" {print \$4}")
echo "30.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_306CLIENT_PID=$!
sleep .1
_306CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_306CLIENT_PID/./chat-client\" {print \$4}")
echo "30.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_307CLIENT_PID=$!
sleep .1
_307CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_307CLIENT_PID/./chat-client\" {print \$4}")
echo "30.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_308CLIENT_PID=$!
sleep .1
_308CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_308CLIENT_PID/./chat-client\" {print \$4}")
echo "30.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_309CLIENT_PID=$!
sleep .1
_309CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_309CLIENT_PID/./chat-client\" {print \$4}")
echo "30.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_310CLIENT_PID=$!
sleep .1
_310CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_310CLIENT_PID/./chat-client\" {print \$4}")
echo "31.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_311CLIENT_PID=$!
sleep .1
_311CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_311CLIENT_PID/./chat-client\" {print \$4}")
echo "31.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_312CLIENT_PID=$!
sleep .1
_312CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_312CLIENT_PID/./chat-client\" {print \$4}")
echo "31.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_313CLIENT_PID=$!
sleep .1
_313CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_313CLIENT_PID/./chat-client\" {print \$4}")
echo "31.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_314CLIENT_PID=$!
sleep .1
_314CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_314CLIENT_PID/./chat-client\" {print \$4}")
echo "31.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_315CLIENT_PID=$!
sleep .1
_315CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_315CLIENT_PID/./chat-client\" {print \$4}")
echo "31.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_316CLIENT_PID=$!
sleep .1
_316CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_316CLIENT_PID/./chat-client\" {print \$4}")
echo "31.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_317CLIENT_PID=$!
sleep .1
_317CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_317CLIENT_PID/./chat-client\" {print \$4}")
echo "31.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_318CLIENT_PID=$!
sleep .1
_318CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_318CLIENT_PID/./chat-client\" {print \$4}")
echo "31.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_319CLIENT_PID=$!
sleep .1
_319CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_319CLIENT_PID/./chat-client\" {print \$4}")
echo "31.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_320CLIENT_PID=$!
sleep .1
_320CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_320CLIENT_PID/./chat-client\" {print \$4}")
echo "32.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_321CLIENT_PID=$!
sleep .1
_321CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_321CLIENT_PID/./chat-client\" {print \$4}")
echo "32.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_322CLIENT_PID=$!
sleep .1
_322CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_322CLIENT_PID/./chat-client\" {print \$4}")
echo "32.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_323CLIENT_PID=$!
sleep .1
_323CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_323CLIENT_PID/./chat-client\" {print \$4}")
echo "32.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_324CLIENT_PID=$!
sleep .1
_324CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_324CLIENT_PID/./chat-client\" {print \$4}")
echo "32.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_325CLIENT_PID=$!
sleep .1
_325CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_325CLIENT_PID/./chat-client\" {print \$4}")
echo "32.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_326CLIENT_PID=$!
sleep .1
_326CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_326CLIENT_PID/./chat-client\" {print \$4}")
echo "32.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_327CLIENT_PID=$!
sleep .1
_327CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_327CLIENT_PID/./chat-client\" {print \$4}")
echo "32.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_328CLIENT_PID=$!
sleep .1
_328CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_328CLIENT_PID/./chat-client\" {print \$4}")
echo "32.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_329CLIENT_PID=$!
sleep .1
_329CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_329CLIENT_PID/./chat-client\" {print \$4}")
echo "32.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_330CLIENT_PID=$!
sleep .1
_330CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_330CLIENT_PID/./chat-client\" {print \$4}")
echo "33.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_331CLIENT_PID=$!
sleep .1
_331CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_331CLIENT_PID/./chat-client\" {print \$4}")
echo "33.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_332CLIENT_PID=$!
sleep .1
_332CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_332CLIENT_PID/./chat-client\" {print \$4}")
echo "33.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_333CLIENT_PID=$!
sleep .1
_333CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_333CLIENT_PID/./chat-client\" {print \$4}")
echo "33.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_334CLIENT_PID=$!
sleep .1
_334CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_334CLIENT_PID/./chat-client\" {print \$4}")
echo "33.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_335CLIENT_PID=$!
sleep .1
_335CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_335CLIENT_PID/./chat-client\" {print \$4}")
echo "33.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_336CLIENT_PID=$!
sleep .1
_336CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_336CLIENT_PID/./chat-client\" {print \$4}")
echo "33.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_337CLIENT_PID=$!
sleep .1
_337CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_337CLIENT_PID/./chat-client\" {print \$4}")
echo "33.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_338CLIENT_PID=$!
sleep .1
_338CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_338CLIENT_PID/./chat-client\" {print \$4}")
echo "33.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_339CLIENT_PID=$!
sleep .1
_339CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_339CLIENT_PID/./chat-client\" {print \$4}")
echo "33.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_340CLIENT_PID=$!
sleep .1
_340CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_340CLIENT_PID/./chat-client\" {print \$4}")
echo "34.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_341CLIENT_PID=$!
sleep .1
_341CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_341CLIENT_PID/./chat-client\" {print \$4}")
echo "34.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_342CLIENT_PID=$!
sleep .1
_342CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_342CLIENT_PID/./chat-client\" {print \$4}")
echo "34.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_343CLIENT_PID=$!
sleep .1
_343CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_343CLIENT_PID/./chat-client\" {print \$4}")
echo "34.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_344CLIENT_PID=$!
sleep .1
_344CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_344CLIENT_PID/./chat-client\" {print \$4}")
echo "34.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_345CLIENT_PID=$!
sleep .1
_345CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_345CLIENT_PID/./chat-client\" {print \$4}")
echo "34.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_346CLIENT_PID=$!
sleep .1
_346CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_346CLIENT_PID/./chat-client\" {print \$4}")
echo "34.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_347CLIENT_PID=$!
sleep .1
_347CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_347CLIENT_PID/./chat-client\" {print \$4}")
echo "34.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_348CLIENT_PID=$!
sleep .1
_348CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_348CLIENT_PID/./chat-client\" {print \$4}")
echo "34.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_349CLIENT_PID=$!
sleep .1
_349CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_349CLIENT_PID/./chat-client\" {print \$4}")
echo "34.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_350CLIENT_PID=$!
sleep .1
_350CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_350CLIENT_PID/./chat-client\" {print \$4}")
echo "35.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_351CLIENT_PID=$!
sleep .1
_351CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_351CLIENT_PID/./chat-client\" {print \$4}")
echo "35.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_352CLIENT_PID=$!
sleep .1
_352CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_352CLIENT_PID/./chat-client\" {print \$4}")
echo "35.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_353CLIENT_PID=$!
sleep .1
_353CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_353CLIENT_PID/./chat-client\" {print \$4}")
echo "35.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_354CLIENT_PID=$!
sleep .1
_354CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_354CLIENT_PID/./chat-client\" {print \$4}")
echo "35.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_355CLIENT_PID=$!
sleep .1
_355CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_355CLIENT_PID/./chat-client\" {print \$4}")
echo "35.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_356CLIENT_PID=$!
sleep .1
_356CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_356CLIENT_PID/./chat-client\" {print \$4}")
echo "35.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_357CLIENT_PID=$!
sleep .1
_357CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_357CLIENT_PID/./chat-client\" {print \$4}")
echo "35.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_358CLIENT_PID=$!
sleep .1
_358CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_358CLIENT_PID/./chat-client\" {print \$4}")
echo "35.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_359CLIENT_PID=$!
sleep .1
_359CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_359CLIENT_PID/./chat-client\" {print \$4}")
echo "35.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_360CLIENT_PID=$!
sleep .1
_360CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_360CLIENT_PID/./chat-client\" {print \$4}")
echo "36.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_361CLIENT_PID=$!
sleep .1
_361CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_361CLIENT_PID/./chat-client\" {print \$4}")
echo "36.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_362CLIENT_PID=$!
sleep .1
_362CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_362CLIENT_PID/./chat-client\" {print \$4}")
echo "36.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_363CLIENT_PID=$!
sleep .1
_363CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_363CLIENT_PID/./chat-client\" {print \$4}")
echo "36.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_364CLIENT_PID=$!
sleep .1
_364CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_364CLIENT_PID/./chat-client\" {print \$4}")
echo "36.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_365CLIENT_PID=$!
sleep .1
_365CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_365CLIENT_PID/./chat-client\" {print \$4}")
echo "36.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_366CLIENT_PID=$!
sleep .1
_366CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_366CLIENT_PID/./chat-client\" {print \$4}")
echo "36.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_367CLIENT_PID=$!
sleep .1
_367CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_367CLIENT_PID/./chat-client\" {print \$4}")
echo "36.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_368CLIENT_PID=$!
sleep .1
_368CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_368CLIENT_PID/./chat-client\" {print \$4}")
echo "36.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_369CLIENT_PID=$!
sleep .1
_369CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_369CLIENT_PID/./chat-client\" {print \$4}")
echo "36.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_370CLIENT_PID=$!
sleep .1
_370CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_370CLIENT_PID/./chat-client\" {print \$4}")
echo "37.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_371CLIENT_PID=$!
sleep .1
_371CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_371CLIENT_PID/./chat-client\" {print \$4}")
echo "37.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_372CLIENT_PID=$!
sleep .1
_372CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_372CLIENT_PID/./chat-client\" {print \$4}")
echo "37.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_373CLIENT_PID=$!
sleep .1
_373CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_373CLIENT_PID/./chat-client\" {print \$4}")
echo "37.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_374CLIENT_PID=$!
sleep .1
_374CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_374CLIENT_PID/./chat-client\" {print \$4}")
echo "37.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_375CLIENT_PID=$!
sleep .1
_375CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_375CLIENT_PID/./chat-client\" {print \$4}")
echo "37.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_376CLIENT_PID=$!
sleep .1
_376CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_376CLIENT_PID/./chat-client\" {print \$4}")
echo "37.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_377CLIENT_PID=$!
sleep .1
_377CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_377CLIENT_PID/./chat-client\" {print \$4}")
echo "37.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_378CLIENT_PID=$!
sleep .1
_378CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_378CLIENT_PID/./chat-client\" {print \$4}")
echo "37.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_379CLIENT_PID=$!
sleep .1
_379CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_379CLIENT_PID/./chat-client\" {print \$4}")
echo "37.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_380CLIENT_PID=$!
sleep .1
_380CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_380CLIENT_PID/./chat-client\" {print \$4}")
echo "38.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_381CLIENT_PID=$!
sleep .1
_381CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_381CLIENT_PID/./chat-client\" {print \$4}")
echo "38.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_382CLIENT_PID=$!
sleep .1
_382CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_382CLIENT_PID/./chat-client\" {print \$4}")
echo "38.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_383CLIENT_PID=$!
sleep .1
_383CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_383CLIENT_PID/./chat-client\" {print \$4}")
echo "38.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_384CLIENT_PID=$!
sleep .1
_384CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_384CLIENT_PID/./chat-client\" {print \$4}")
echo "38.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_385CLIENT_PID=$!
sleep .1
_385CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_385CLIENT_PID/./chat-client\" {print \$4}")
echo "38.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_386CLIENT_PID=$!
sleep .1
_386CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_386CLIENT_PID/./chat-client\" {print \$4}")
echo "38.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_387CLIENT_PID=$!
sleep .1
_387CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_387CLIENT_PID/./chat-client\" {print \$4}")
echo "38.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_388CLIENT_PID=$!
sleep .1
_388CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_388CLIENT_PID/./chat-client\" {print \$4}")
echo "38.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_389CLIENT_PID=$!
sleep .1
_389CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_389CLIENT_PID/./chat-client\" {print \$4}")
echo "38.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_390CLIENT_PID=$!
sleep .1
_390CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_390CLIENT_PID/./chat-client\" {print \$4}")
echo "39.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_391CLIENT_PID=$!
sleep .1
_391CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_391CLIENT_PID/./chat-client\" {print \$4}")
echo "39.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_392CLIENT_PID=$!
sleep .1
_392CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_392CLIENT_PID/./chat-client\" {print \$4}")
echo "39.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_393CLIENT_PID=$!
sleep .1
_393CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_393CLIENT_PID/./chat-client\" {print \$4}")
echo "39.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_394CLIENT_PID=$!
sleep .1
_394CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_394CLIENT_PID/./chat-client\" {print \$4}")
echo "39.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_395CLIENT_PID=$!
sleep .1
_395CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_395CLIENT_PID/./chat-client\" {print \$4}")
echo "39.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_396CLIENT_PID=$!
sleep .1
_396CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_396CLIENT_PID/./chat-client\" {print \$4}")
echo "39.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_397CLIENT_PID=$!
sleep .1
_397CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_397CLIENT_PID/./chat-client\" {print \$4}")
echo "39.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_398CLIENT_PID=$!
sleep .1
_398CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_398CLIENT_PID/./chat-client\" {print \$4}")
echo "39.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_399CLIENT_PID=$!
sleep .1
_399CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_399CLIENT_PID/./chat-client\" {print \$4}")
echo "39.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_400CLIENT_PID=$!
sleep .1
_400CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_400CLIENT_PID/./chat-client\" {print \$4}")
echo "40.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_401CLIENT_PID=$!
sleep .1
_401CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_401CLIENT_PID/./chat-client\" {print \$4}")
echo "40.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_402CLIENT_PID=$!
sleep .1
_402CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_402CLIENT_PID/./chat-client\" {print \$4}")
echo "40.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_403CLIENT_PID=$!
sleep .1
_403CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_403CLIENT_PID/./chat-client\" {print \$4}")
echo "40.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_404CLIENT_PID=$!
sleep .1
_404CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_404CLIENT_PID/./chat-client\" {print \$4}")
echo "40.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_405CLIENT_PID=$!
sleep .1
_405CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_405CLIENT_PID/./chat-client\" {print \$4}")
echo "40.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_406CLIENT_PID=$!
sleep .1
_406CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_406CLIENT_PID/./chat-client\" {print \$4}")
echo "40.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_407CLIENT_PID=$!
sleep .1
_407CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_407CLIENT_PID/./chat-client\" {print \$4}")
echo "40.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_408CLIENT_PID=$!
sleep .1
_408CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_408CLIENT_PID/./chat-client\" {print \$4}")
echo "40.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_409CLIENT_PID=$!
sleep .1
_409CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_409CLIENT_PID/./chat-client\" {print \$4}")
echo "40.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_410CLIENT_PID=$!
sleep .1
_410CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_410CLIENT_PID/./chat-client\" {print \$4}")
echo "41.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_411CLIENT_PID=$!
sleep .1
_411CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_411CLIENT_PID/./chat-client\" {print \$4}")
echo "41.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_412CLIENT_PID=$!
sleep .1
_412CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_412CLIENT_PID/./chat-client\" {print \$4}")
echo "41.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_413CLIENT_PID=$!
sleep .1
_413CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_413CLIENT_PID/./chat-client\" {print \$4}")
echo "41.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_414CLIENT_PID=$!
sleep .1
_414CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_414CLIENT_PID/./chat-client\" {print \$4}")
echo "41.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_415CLIENT_PID=$!
sleep .1
_415CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_415CLIENT_PID/./chat-client\" {print \$4}")
echo "41.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_416CLIENT_PID=$!
sleep .1
_416CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_416CLIENT_PID/./chat-client\" {print \$4}")
echo "41.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_417CLIENT_PID=$!
sleep .1
_417CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_417CLIENT_PID/./chat-client\" {print \$4}")
echo "41.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_418CLIENT_PID=$!
sleep .1
_418CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_418CLIENT_PID/./chat-client\" {print \$4}")
echo "41.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_419CLIENT_PID=$!
sleep .1
_419CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_419CLIENT_PID/./chat-client\" {print \$4}")
echo "41.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_420CLIENT_PID=$!
sleep .1
_420CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_420CLIENT_PID/./chat-client\" {print \$4}")
echo "42.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_421CLIENT_PID=$!
sleep .1
_421CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_421CLIENT_PID/./chat-client\" {print \$4}")
echo "42.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_422CLIENT_PID=$!
sleep .1
_422CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_422CLIENT_PID/./chat-client\" {print \$4}")
echo "42.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_423CLIENT_PID=$!
sleep .1
_423CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_423CLIENT_PID/./chat-client\" {print \$4}")
echo "42.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_424CLIENT_PID=$!
sleep .1
_424CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_424CLIENT_PID/./chat-client\" {print \$4}")
echo "42.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_425CLIENT_PID=$!
sleep .1
_425CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_425CLIENT_PID/./chat-client\" {print \$4}")
echo "42.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_426CLIENT_PID=$!
sleep .1
_426CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_426CLIENT_PID/./chat-client\" {print \$4}")
echo "42.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_427CLIENT_PID=$!
sleep .1
_427CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_427CLIENT_PID/./chat-client\" {print \$4}")
echo "42.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_428CLIENT_PID=$!
sleep .1
_428CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_428CLIENT_PID/./chat-client\" {print \$4}")
echo "42.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_429CLIENT_PID=$!
sleep .1
_429CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_429CLIENT_PID/./chat-client\" {print \$4}")
echo "42.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_430CLIENT_PID=$!
sleep .1
_430CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_430CLIENT_PID/./chat-client\" {print \$4}")
echo "43.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_431CLIENT_PID=$!
sleep .1
_431CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_431CLIENT_PID/./chat-client\" {print \$4}")
echo "43.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_432CLIENT_PID=$!
sleep .1
_432CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_432CLIENT_PID/./chat-client\" {print \$4}")
echo "43.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_433CLIENT_PID=$!
sleep .1
_433CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_433CLIENT_PID/./chat-client\" {print \$4}")
echo "43.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_434CLIENT_PID=$!
sleep .1
_434CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_434CLIENT_PID/./chat-client\" {print \$4}")
echo "43.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_435CLIENT_PID=$!
sleep .1
_435CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_435CLIENT_PID/./chat-client\" {print \$4}")
echo "43.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_436CLIENT_PID=$!
sleep .1
_436CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_436CLIENT_PID/./chat-client\" {print \$4}")
echo "43.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_437CLIENT_PID=$!
sleep .1
_437CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_437CLIENT_PID/./chat-client\" {print \$4}")
echo "43.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_438CLIENT_PID=$!
sleep .1
_438CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_438CLIENT_PID/./chat-client\" {print \$4}")
echo "43.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_439CLIENT_PID=$!
sleep .1
_439CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_439CLIENT_PID/./chat-client\" {print \$4}")
echo "43.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_440CLIENT_PID=$!
sleep .1
_440CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_440CLIENT_PID/./chat-client\" {print \$4}")
echo "44.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_441CLIENT_PID=$!
sleep .1
_441CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_441CLIENT_PID/./chat-client\" {print \$4}")
echo "44.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_442CLIENT_PID=$!
sleep .1
_442CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_442CLIENT_PID/./chat-client\" {print \$4}")
echo "44.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_443CLIENT_PID=$!
sleep .1
_443CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_443CLIENT_PID/./chat-client\" {print \$4}")
echo "44.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_444CLIENT_PID=$!
sleep .1
_444CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_444CLIENT_PID/./chat-client\" {print \$4}")
echo "44.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_445CLIENT_PID=$!
sleep .1
_445CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_445CLIENT_PID/./chat-client\" {print \$4}")
echo "44.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_446CLIENT_PID=$!
sleep .1
_446CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_446CLIENT_PID/./chat-client\" {print \$4}")
echo "44.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_447CLIENT_PID=$!
sleep .1
_447CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_447CLIENT_PID/./chat-client\" {print \$4}")
echo "44.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_448CLIENT_PID=$!
sleep .1
_448CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_448CLIENT_PID/./chat-client\" {print \$4}")
echo "44.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_449CLIENT_PID=$!
sleep .1
_449CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_449CLIENT_PID/./chat-client\" {print \$4}")
echo "44.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_450CLIENT_PID=$!
sleep .1
_450CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_450CLIENT_PID/./chat-client\" {print \$4}")
echo "45.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_451CLIENT_PID=$!
sleep .1
_451CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_451CLIENT_PID/./chat-client\" {print \$4}")
echo "45.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_452CLIENT_PID=$!
sleep .1
_452CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_452CLIENT_PID/./chat-client\" {print \$4}")
echo "45.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_453CLIENT_PID=$!
sleep .1
_453CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_453CLIENT_PID/./chat-client\" {print \$4}")
echo "45.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_454CLIENT_PID=$!
sleep .1
_454CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_454CLIENT_PID/./chat-client\" {print \$4}")
echo "45.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_455CLIENT_PID=$!
sleep .1
_455CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_455CLIENT_PID/./chat-client\" {print \$4}")
echo "45.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_456CLIENT_PID=$!
sleep .1
_456CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_456CLIENT_PID/./chat-client\" {print \$4}")
echo "45.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_457CLIENT_PID=$!
sleep .1
_457CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_457CLIENT_PID/./chat-client\" {print \$4}")
echo "45.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_458CLIENT_PID=$!
sleep .1
_458CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_458CLIENT_PID/./chat-client\" {print \$4}")
echo "45.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_459CLIENT_PID=$!
sleep .1
_459CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_459CLIENT_PID/./chat-client\" {print \$4}")
echo "45.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_460CLIENT_PID=$!
sleep .1
_460CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_460CLIENT_PID/./chat-client\" {print \$4}")
echo "46.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_461CLIENT_PID=$!
sleep .1
_461CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_461CLIENT_PID/./chat-client\" {print \$4}")
echo "46.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_462CLIENT_PID=$!
sleep .1
_462CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_462CLIENT_PID/./chat-client\" {print \$4}")
echo "46.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_463CLIENT_PID=$!
sleep .1
_463CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_463CLIENT_PID/./chat-client\" {print \$4}")
echo "46.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_464CLIENT_PID=$!
sleep .1
_464CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_464CLIENT_PID/./chat-client\" {print \$4}")
echo "46.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_465CLIENT_PID=$!
sleep .1
_465CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_465CLIENT_PID/./chat-client\" {print \$4}")
echo "46.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_466CLIENT_PID=$!
sleep .1
_466CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_466CLIENT_PID/./chat-client\" {print \$4}")
echo "46.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_467CLIENT_PID=$!
sleep .1
_467CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_467CLIENT_PID/./chat-client\" {print \$4}")
echo "46.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_468CLIENT_PID=$!
sleep .1
_468CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_468CLIENT_PID/./chat-client\" {print \$4}")
echo "46.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_469CLIENT_PID=$!
sleep .1
_469CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_469CLIENT_PID/./chat-client\" {print \$4}")
echo "46.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_470CLIENT_PID=$!
sleep .1
_470CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_470CLIENT_PID/./chat-client\" {print \$4}")
echo "47.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_471CLIENT_PID=$!
sleep .1
_471CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_471CLIENT_PID/./chat-client\" {print \$4}")
echo "47.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_472CLIENT_PID=$!
sleep .1
_472CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_472CLIENT_PID/./chat-client\" {print \$4}")
echo "47.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_473CLIENT_PID=$!
sleep .1
_473CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_473CLIENT_PID/./chat-client\" {print \$4}")
echo "47.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_474CLIENT_PID=$!
sleep .1
_474CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_474CLIENT_PID/./chat-client\" {print \$4}")
echo "47.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_475CLIENT_PID=$!
sleep .1
_475CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_475CLIENT_PID/./chat-client\" {print \$4}")
echo "47.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_476CLIENT_PID=$!
sleep .1
_476CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_476CLIENT_PID/./chat-client\" {print \$4}")
echo "47.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_477CLIENT_PID=$!
sleep .1
_477CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_477CLIENT_PID/./chat-client\" {print \$4}")
echo "47.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_478CLIENT_PID=$!
sleep .1
_478CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_478CLIENT_PID/./chat-client\" {print \$4}")
echo "47.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_479CLIENT_PID=$!
sleep .1
_479CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_479CLIENT_PID/./chat-client\" {print \$4}")
echo "47.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_480CLIENT_PID=$!
sleep .1
_480CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_480CLIENT_PID/./chat-client\" {print \$4}")
echo "48.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_481CLIENT_PID=$!
sleep .1
_481CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_481CLIENT_PID/./chat-client\" {print \$4}")
echo "48.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_482CLIENT_PID=$!
sleep .1
_482CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_482CLIENT_PID/./chat-client\" {print \$4}")
echo "48.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_483CLIENT_PID=$!
sleep .1
_483CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_483CLIENT_PID/./chat-client\" {print \$4}")
echo "48.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_484CLIENT_PID=$!
sleep .1
_484CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_484CLIENT_PID/./chat-client\" {print \$4}")
echo "48.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_485CLIENT_PID=$!
sleep .1
_485CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_485CLIENT_PID/./chat-client\" {print \$4}")
echo "48.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_486CLIENT_PID=$!
sleep .1
_486CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_486CLIENT_PID/./chat-client\" {print \$4}")
echo "48.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_487CLIENT_PID=$!
sleep .1
_487CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_487CLIENT_PID/./chat-client\" {print \$4}")
echo "48.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_488CLIENT_PID=$!
sleep .1
_488CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_488CLIENT_PID/./chat-client\" {print \$4}")
echo "48.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_489CLIENT_PID=$!
sleep .1
_489CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_489CLIENT_PID/./chat-client\" {print \$4}")
echo "48.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_490CLIENT_PID=$!
sleep .1
_490CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_490CLIENT_PID/./chat-client\" {print \$4}")
echo "49.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_491CLIENT_PID=$!
sleep .1
_491CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_491CLIENT_PID/./chat-client\" {print \$4}")
echo "49.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_492CLIENT_PID=$!
sleep .1
_492CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_492CLIENT_PID/./chat-client\" {print \$4}")
echo "49.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_493CLIENT_PID=$!
sleep .1
_493CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_493CLIENT_PID/./chat-client\" {print \$4}")
echo "49.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_494CLIENT_PID=$!
sleep .1
_494CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_494CLIENT_PID/./chat-client\" {print \$4}")
echo "49.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_495CLIENT_PID=$!
sleep .1
_495CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_495CLIENT_PID/./chat-client\" {print \$4}")
echo "49.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_496CLIENT_PID=$!
sleep .1
_496CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_496CLIENT_PID/./chat-client\" {print \$4}")
echo "49.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_497CLIENT_PID=$!
sleep .1
_497CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_497CLIENT_PID/./chat-client\" {print \$4}")
echo "49.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_498CLIENT_PID=$!
sleep .1
_498CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_498CLIENT_PID/./chat-client\" {print \$4}")
echo "49.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_499CLIENT_PID=$!
sleep .1
_499CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_499CLIENT_PID/./chat-client\" {print \$4}")
echo "49.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_500CLIENT_PID=$!
sleep .1
_500CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_500CLIENT_PID/./chat-client\" {print \$4}")
echo "50.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_501CLIENT_PID=$!
sleep .1
_501CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_501CLIENT_PID/./chat-client\" {print \$4}")
echo "50.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_502CLIENT_PID=$!
sleep .1
_502CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_502CLIENT_PID/./chat-client\" {print \$4}")
echo "50.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_503CLIENT_PID=$!
sleep .1
_503CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_503CLIENT_PID/./chat-client\" {print \$4}")
echo "50.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_504CLIENT_PID=$!
sleep .1
_504CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_504CLIENT_PID/./chat-client\" {print \$4}")
echo "50.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_505CLIENT_PID=$!
sleep .1
_505CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_505CLIENT_PID/./chat-client\" {print \$4}")
echo "50.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_506CLIENT_PID=$!
sleep .1
_506CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_506CLIENT_PID/./chat-client\" {print \$4}")
echo "50.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_507CLIENT_PID=$!
sleep .1
_507CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_507CLIENT_PID/./chat-client\" {print \$4}")
echo "50.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_508CLIENT_PID=$!
sleep .1
_508CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_508CLIENT_PID/./chat-client\" {print \$4}")
echo "50.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_509CLIENT_PID=$!
sleep .1
_509CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_509CLIENT_PID/./chat-client\" {print \$4}")
echo "50.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_510CLIENT_PID=$!
sleep .1
_510CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_510CLIENT_PID/./chat-client\" {print \$4}")
echo "51.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_511CLIENT_PID=$!
sleep .1
_511CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_511CLIENT_PID/./chat-client\" {print \$4}")
echo "51.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_512CLIENT_PID=$!
sleep .1
_512CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_512CLIENT_PID/./chat-client\" {print \$4}")
echo "51.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_513CLIENT_PID=$!
sleep .1
_513CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_513CLIENT_PID/./chat-client\" {print \$4}")
echo "51.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_514CLIENT_PID=$!
sleep .1
_514CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_514CLIENT_PID/./chat-client\" {print \$4}")
echo "51.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_515CLIENT_PID=$!
sleep .1
_515CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_515CLIENT_PID/./chat-client\" {print \$4}")
echo "51.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_516CLIENT_PID=$!
sleep .1
_516CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_516CLIENT_PID/./chat-client\" {print \$4}")
echo "51.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_517CLIENT_PID=$!
sleep .1
_517CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_517CLIENT_PID/./chat-client\" {print \$4}")
echo "51.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_518CLIENT_PID=$!
sleep .1
_518CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_518CLIENT_PID/./chat-client\" {print \$4}")
echo "51.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_519CLIENT_PID=$!
sleep .1
_519CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_519CLIENT_PID/./chat-client\" {print \$4}")
echo "51.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_520CLIENT_PID=$!
sleep .1
_520CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_520CLIENT_PID/./chat-client\" {print \$4}")
echo "52.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_521CLIENT_PID=$!
sleep .1
_521CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_521CLIENT_PID/./chat-client\" {print \$4}")
echo "52.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_522CLIENT_PID=$!
sleep .1
_522CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_522CLIENT_PID/./chat-client\" {print \$4}")
echo "52.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_523CLIENT_PID=$!
sleep .1
_523CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_523CLIENT_PID/./chat-client\" {print \$4}")
echo "52.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_524CLIENT_PID=$!
sleep .1
_524CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_524CLIENT_PID/./chat-client\" {print \$4}")
echo "52.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_525CLIENT_PID=$!
sleep .1
_525CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_525CLIENT_PID/./chat-client\" {print \$4}")
echo "52.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_526CLIENT_PID=$!
sleep .1
_526CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_526CLIENT_PID/./chat-client\" {print \$4}")
echo "52.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_527CLIENT_PID=$!
sleep .1
_527CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_527CLIENT_PID/./chat-client\" {print \$4}")
echo "52.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_528CLIENT_PID=$!
sleep .1
_528CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_528CLIENT_PID/./chat-client\" {print \$4}")
echo "52.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_529CLIENT_PID=$!
sleep .1
_529CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_529CLIENT_PID/./chat-client\" {print \$4}")
echo "52.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_530CLIENT_PID=$!
sleep .1
_530CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_530CLIENT_PID/./chat-client\" {print \$4}")
echo "53.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_531CLIENT_PID=$!
sleep .1
_531CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_531CLIENT_PID/./chat-client\" {print \$4}")
echo "53.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_532CLIENT_PID=$!
sleep .1
_532CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_532CLIENT_PID/./chat-client\" {print \$4}")
echo "53.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_533CLIENT_PID=$!
sleep .1
_533CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_533CLIENT_PID/./chat-client\" {print \$4}")
echo "53.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_534CLIENT_PID=$!
sleep .1
_534CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_534CLIENT_PID/./chat-client\" {print \$4}")
echo "53.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_535CLIENT_PID=$!
sleep .1
_535CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_535CLIENT_PID/./chat-client\" {print \$4}")
echo "53.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_536CLIENT_PID=$!
sleep .1
_536CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_536CLIENT_PID/./chat-client\" {print \$4}")
echo "53.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_537CLIENT_PID=$!
sleep .1
_537CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_537CLIENT_PID/./chat-client\" {print \$4}")
echo "53.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_538CLIENT_PID=$!
sleep .1
_538CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_538CLIENT_PID/./chat-client\" {print \$4}")
echo "53.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_539CLIENT_PID=$!
sleep .1
_539CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_539CLIENT_PID/./chat-client\" {print \$4}")
echo "53.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_540CLIENT_PID=$!
sleep .1
_540CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_540CLIENT_PID/./chat-client\" {print \$4}")
echo "54.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_541CLIENT_PID=$!
sleep .1
_541CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_541CLIENT_PID/./chat-client\" {print \$4}")
echo "54.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_542CLIENT_PID=$!
sleep .1
_542CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_542CLIENT_PID/./chat-client\" {print \$4}")
echo "54.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_543CLIENT_PID=$!
sleep .1
_543CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_543CLIENT_PID/./chat-client\" {print \$4}")
echo "54.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_544CLIENT_PID=$!
sleep .1
_544CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_544CLIENT_PID/./chat-client\" {print \$4}")
echo "54.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_545CLIENT_PID=$!
sleep .1
_545CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_545CLIENT_PID/./chat-client\" {print \$4}")
echo "54.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_546CLIENT_PID=$!
sleep .1
_546CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_546CLIENT_PID/./chat-client\" {print \$4}")
echo "54.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_547CLIENT_PID=$!
sleep .1
_547CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_547CLIENT_PID/./chat-client\" {print \$4}")
echo "54.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_548CLIENT_PID=$!
sleep .1
_548CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_548CLIENT_PID/./chat-client\" {print \$4}")
echo "54.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_549CLIENT_PID=$!
sleep .1
_549CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_549CLIENT_PID/./chat-client\" {print \$4}")
echo "54.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_550CLIENT_PID=$!
sleep .1
_550CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_550CLIENT_PID/./chat-client\" {print \$4}")
echo "55.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_551CLIENT_PID=$!
sleep .1
_551CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_551CLIENT_PID/./chat-client\" {print \$4}")
echo "55.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_552CLIENT_PID=$!
sleep .1
_552CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_552CLIENT_PID/./chat-client\" {print \$4}")
echo "55.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_553CLIENT_PID=$!
sleep .1
_553CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_553CLIENT_PID/./chat-client\" {print \$4}")
echo "55.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_554CLIENT_PID=$!
sleep .1
_554CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_554CLIENT_PID/./chat-client\" {print \$4}")
echo "55.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_555CLIENT_PID=$!
sleep .1
_555CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_555CLIENT_PID/./chat-client\" {print \$4}")
echo "55.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_556CLIENT_PID=$!
sleep .1
_556CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_556CLIENT_PID/./chat-client\" {print \$4}")
echo "55.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_557CLIENT_PID=$!
sleep .1
_557CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_557CLIENT_PID/./chat-client\" {print \$4}")
echo "55.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_558CLIENT_PID=$!
sleep .1
_558CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_558CLIENT_PID/./chat-client\" {print \$4}")
echo "55.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_559CLIENT_PID=$!
sleep .1
_559CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_559CLIENT_PID/./chat-client\" {print \$4}")
echo "55.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_560CLIENT_PID=$!
sleep .1
_560CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_560CLIENT_PID/./chat-client\" {print \$4}")
echo "56.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_561CLIENT_PID=$!
sleep .1
_561CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_561CLIENT_PID/./chat-client\" {print \$4}")
echo "56.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_562CLIENT_PID=$!
sleep .1
_562CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_562CLIENT_PID/./chat-client\" {print \$4}")
echo "56.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_563CLIENT_PID=$!
sleep .1
_563CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_563CLIENT_PID/./chat-client\" {print \$4}")
echo "56.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_564CLIENT_PID=$!
sleep .1
_564CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_564CLIENT_PID/./chat-client\" {print \$4}")
echo "56.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_565CLIENT_PID=$!
sleep .1
_565CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_565CLIENT_PID/./chat-client\" {print \$4}")
echo "56.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_566CLIENT_PID=$!
sleep .1
_566CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_566CLIENT_PID/./chat-client\" {print \$4}")
echo "56.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_567CLIENT_PID=$!
sleep .1
_567CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_567CLIENT_PID/./chat-client\" {print \$4}")
echo "56.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_568CLIENT_PID=$!
sleep .1
_568CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_568CLIENT_PID/./chat-client\" {print \$4}")
echo "56.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_569CLIENT_PID=$!
sleep .1
_569CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_569CLIENT_PID/./chat-client\" {print \$4}")
echo "56.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_570CLIENT_PID=$!
sleep .1
_570CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_570CLIENT_PID/./chat-client\" {print \$4}")
echo "57.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_571CLIENT_PID=$!
sleep .1
_571CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_571CLIENT_PID/./chat-client\" {print \$4}")
echo "57.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_572CLIENT_PID=$!
sleep .1
_572CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_572CLIENT_PID/./chat-client\" {print \$4}")
echo "57.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_573CLIENT_PID=$!
sleep .1
_573CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_573CLIENT_PID/./chat-client\" {print \$4}")
echo "57.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_574CLIENT_PID=$!
sleep .1
_574CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_574CLIENT_PID/./chat-client\" {print \$4}")
echo "57.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_575CLIENT_PID=$!
sleep .1
_575CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_575CLIENT_PID/./chat-client\" {print \$4}")
echo "57.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_576CLIENT_PID=$!
sleep .1
_576CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_576CLIENT_PID/./chat-client\" {print \$4}")
echo "57.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_577CLIENT_PID=$!
sleep .1
_577CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_577CLIENT_PID/./chat-client\" {print \$4}")
echo "57.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_578CLIENT_PID=$!
sleep .1
_578CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_578CLIENT_PID/./chat-client\" {print \$4}")
echo "57.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_579CLIENT_PID=$!
sleep .1
_579CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_579CLIENT_PID/./chat-client\" {print \$4}")
echo "57.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_580CLIENT_PID=$!
sleep .1
_580CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_580CLIENT_PID/./chat-client\" {print \$4}")
echo "58.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_581CLIENT_PID=$!
sleep .1
_581CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_581CLIENT_PID/./chat-client\" {print \$4}")
echo "58.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_582CLIENT_PID=$!
sleep .1
_582CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_582CLIENT_PID/./chat-client\" {print \$4}")
echo "58.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_583CLIENT_PID=$!
sleep .1
_583CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_583CLIENT_PID/./chat-client\" {print \$4}")
echo "58.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_584CLIENT_PID=$!
sleep .1
_584CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_584CLIENT_PID/./chat-client\" {print \$4}")
echo "58.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_585CLIENT_PID=$!
sleep .1
_585CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_585CLIENT_PID/./chat-client\" {print \$4}")
echo "58.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_586CLIENT_PID=$!
sleep .1
_586CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_586CLIENT_PID/./chat-client\" {print \$4}")
echo "58.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_587CLIENT_PID=$!
sleep .1
_587CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_587CLIENT_PID/./chat-client\" {print \$4}")
echo "58.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_588CLIENT_PID=$!
sleep .1
_588CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_588CLIENT_PID/./chat-client\" {print \$4}")
echo "58.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_589CLIENT_PID=$!
sleep .1
_589CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_589CLIENT_PID/./chat-client\" {print \$4}")
echo "58.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_590CLIENT_PID=$!
sleep .1
_590CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_590CLIENT_PID/./chat-client\" {print \$4}")
echo "59.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_591CLIENT_PID=$!
sleep .1
_591CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_591CLIENT_PID/./chat-client\" {print \$4}")
echo "59.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_592CLIENT_PID=$!
sleep .1
_592CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_592CLIENT_PID/./chat-client\" {print \$4}")
echo "59.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_593CLIENT_PID=$!
sleep .1
_593CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_593CLIENT_PID/./chat-client\" {print \$4}")
echo "59.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_594CLIENT_PID=$!
sleep .1
_594CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_594CLIENT_PID/./chat-client\" {print \$4}")
echo "59.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_595CLIENT_PID=$!
sleep .1
_595CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_595CLIENT_PID/./chat-client\" {print \$4}")
echo "59.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_596CLIENT_PID=$!
sleep .1
_596CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_596CLIENT_PID/./chat-client\" {print \$4}")
echo "59.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_597CLIENT_PID=$!
sleep .1
_597CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_597CLIENT_PID/./chat-client\" {print \$4}")
echo "59.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_598CLIENT_PID=$!
sleep .1
_598CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_598CLIENT_PID/./chat-client\" {print \$4}")
echo "59.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_599CLIENT_PID=$!
sleep .1
_599CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_599CLIENT_PID/./chat-client\" {print \$4}")
echo "59.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_600CLIENT_PID=$!
sleep .1
_600CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_600CLIENT_PID/./chat-client\" {print \$4}")
echo "60.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_601CLIENT_PID=$!
sleep .1
_601CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_601CLIENT_PID/./chat-client\" {print \$4}")
echo "60.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_602CLIENT_PID=$!
sleep .1
_602CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_602CLIENT_PID/./chat-client\" {print \$4}")
echo "60.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_603CLIENT_PID=$!
sleep .1
_603CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_603CLIENT_PID/./chat-client\" {print \$4}")
echo "60.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_604CLIENT_PID=$!
sleep .1
_604CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_604CLIENT_PID/./chat-client\" {print \$4}")
echo "60.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_605CLIENT_PID=$!
sleep .1
_605CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_605CLIENT_PID/./chat-client\" {print \$4}")
echo "60.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_606CLIENT_PID=$!
sleep .1
_606CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_606CLIENT_PID/./chat-client\" {print \$4}")
echo "60.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_607CLIENT_PID=$!
sleep .1
_607CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_607CLIENT_PID/./chat-client\" {print \$4}")
echo "60.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_608CLIENT_PID=$!
sleep .1
_608CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_608CLIENT_PID/./chat-client\" {print \$4}")
echo "60.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_609CLIENT_PID=$!
sleep .1
_609CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_609CLIENT_PID/./chat-client\" {print \$4}")
echo "60.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_610CLIENT_PID=$!
sleep .1
_610CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_610CLIENT_PID/./chat-client\" {print \$4}")
echo "61.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_611CLIENT_PID=$!
sleep .1
_611CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_611CLIENT_PID/./chat-client\" {print \$4}")
echo "61.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_612CLIENT_PID=$!
sleep .1
_612CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_612CLIENT_PID/./chat-client\" {print \$4}")
echo "61.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_613CLIENT_PID=$!
sleep .1
_613CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_613CLIENT_PID/./chat-client\" {print \$4}")
echo "61.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_614CLIENT_PID=$!
sleep .1
_614CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_614CLIENT_PID/./chat-client\" {print \$4}")
echo "61.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_615CLIENT_PID=$!
sleep .1
_615CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_615CLIENT_PID/./chat-client\" {print \$4}")
echo "61.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_616CLIENT_PID=$!
sleep .1
_616CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_616CLIENT_PID/./chat-client\" {print \$4}")
echo "61.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_617CLIENT_PID=$!
sleep .1
_617CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_617CLIENT_PID/./chat-client\" {print \$4}")
echo "61.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_618CLIENT_PID=$!
sleep .1
_618CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_618CLIENT_PID/./chat-client\" {print \$4}")
echo "61.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_619CLIENT_PID=$!
sleep .1
_619CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_619CLIENT_PID/./chat-client\" {print \$4}")
echo "61.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_620CLIENT_PID=$!
sleep .1
_620CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_620CLIENT_PID/./chat-client\" {print \$4}")
echo "62.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_621CLIENT_PID=$!
sleep .1
_621CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_621CLIENT_PID/./chat-client\" {print \$4}")
echo "62.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_622CLIENT_PID=$!
sleep .1
_622CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_622CLIENT_PID/./chat-client\" {print \$4}")
echo "62.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_623CLIENT_PID=$!
sleep .1
_623CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_623CLIENT_PID/./chat-client\" {print \$4}")
echo "62.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_624CLIENT_PID=$!
sleep .1
_624CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_624CLIENT_PID/./chat-client\" {print \$4}")
echo "62.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_625CLIENT_PID=$!
sleep .1
_625CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_625CLIENT_PID/./chat-client\" {print \$4}")
echo "62.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_626CLIENT_PID=$!
sleep .1
_626CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_626CLIENT_PID/./chat-client\" {print \$4}")
echo "62.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_627CLIENT_PID=$!
sleep .1
_627CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_627CLIENT_PID/./chat-client\" {print \$4}")
echo "62.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_628CLIENT_PID=$!
sleep .1
_628CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_628CLIENT_PID/./chat-client\" {print \$4}")
echo "62.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_629CLIENT_PID=$!
sleep .1
_629CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_629CLIENT_PID/./chat-client\" {print \$4}")
echo "62.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_630CLIENT_PID=$!
sleep .1
_630CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_630CLIENT_PID/./chat-client\" {print \$4}")
echo "63.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_631CLIENT_PID=$!
sleep .1
_631CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_631CLIENT_PID/./chat-client\" {print \$4}")
echo "63.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_632CLIENT_PID=$!
sleep .1
_632CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_632CLIENT_PID/./chat-client\" {print \$4}")
echo "63.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_633CLIENT_PID=$!
sleep .1
_633CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_633CLIENT_PID/./chat-client\" {print \$4}")
echo "63.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_634CLIENT_PID=$!
sleep .1
_634CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_634CLIENT_PID/./chat-client\" {print \$4}")
echo "63.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_635CLIENT_PID=$!
sleep .1
_635CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_635CLIENT_PID/./chat-client\" {print \$4}")
echo "63.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_636CLIENT_PID=$!
sleep .1
_636CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_636CLIENT_PID/./chat-client\" {print \$4}")
echo "63.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_637CLIENT_PID=$!
sleep .1
_637CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_637CLIENT_PID/./chat-client\" {print \$4}")
echo "63.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_638CLIENT_PID=$!
sleep .1
_638CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_638CLIENT_PID/./chat-client\" {print \$4}")
echo "63.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_639CLIENT_PID=$!
sleep .1
_639CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_639CLIENT_PID/./chat-client\" {print \$4}")
echo "63.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_640CLIENT_PID=$!
sleep .1
_640CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_640CLIENT_PID/./chat-client\" {print \$4}")
echo "64.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_641CLIENT_PID=$!
sleep .1
_641CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_641CLIENT_PID/./chat-client\" {print \$4}")
echo "64.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_642CLIENT_PID=$!
sleep .1
_642CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_642CLIENT_PID/./chat-client\" {print \$4}")
echo "64.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_643CLIENT_PID=$!
sleep .1
_643CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_643CLIENT_PID/./chat-client\" {print \$4}")
echo "64.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_644CLIENT_PID=$!
sleep .1
_644CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_644CLIENT_PID/./chat-client\" {print \$4}")
echo "64.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_645CLIENT_PID=$!
sleep .1
_645CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_645CLIENT_PID/./chat-client\" {print \$4}")
echo "64.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_646CLIENT_PID=$!
sleep .1
_646CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_646CLIENT_PID/./chat-client\" {print \$4}")
echo "64.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_647CLIENT_PID=$!
sleep .1
_647CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_647CLIENT_PID/./chat-client\" {print \$4}")
echo "64.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_648CLIENT_PID=$!
sleep .1
_648CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_648CLIENT_PID/./chat-client\" {print \$4}")
echo "64.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_649CLIENT_PID=$!
sleep .1
_649CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_649CLIENT_PID/./chat-client\" {print \$4}")
echo "64.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_650CLIENT_PID=$!
sleep .1
_650CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_650CLIENT_PID/./chat-client\" {print \$4}")
echo "65.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_651CLIENT_PID=$!
sleep .1
_651CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_651CLIENT_PID/./chat-client\" {print \$4}")
echo "65.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_652CLIENT_PID=$!
sleep .1
_652CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_652CLIENT_PID/./chat-client\" {print \$4}")
echo "65.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_653CLIENT_PID=$!
sleep .1
_653CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_653CLIENT_PID/./chat-client\" {print \$4}")
echo "65.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_654CLIENT_PID=$!
sleep .1
_654CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_654CLIENT_PID/./chat-client\" {print \$4}")
echo "65.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_655CLIENT_PID=$!
sleep .1
_655CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_655CLIENT_PID/./chat-client\" {print \$4}")
echo "65.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_656CLIENT_PID=$!
sleep .1
_656CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_656CLIENT_PID/./chat-client\" {print \$4}")
echo "65.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_657CLIENT_PID=$!
sleep .1
_657CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_657CLIENT_PID/./chat-client\" {print \$4}")
echo "65.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_658CLIENT_PID=$!
sleep .1
_658CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_658CLIENT_PID/./chat-client\" {print \$4}")
echo "65.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_659CLIENT_PID=$!
sleep .1
_659CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_659CLIENT_PID/./chat-client\" {print \$4}")
echo "65.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_660CLIENT_PID=$!
sleep .1
_660CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_660CLIENT_PID/./chat-client\" {print \$4}")
echo "66.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_661CLIENT_PID=$!
sleep .1
_661CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_661CLIENT_PID/./chat-client\" {print \$4}")
echo "66.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_662CLIENT_PID=$!
sleep .1
_662CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_662CLIENT_PID/./chat-client\" {print \$4}")
echo "66.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_663CLIENT_PID=$!
sleep .1
_663CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_663CLIENT_PID/./chat-client\" {print \$4}")
echo "66.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_664CLIENT_PID=$!
sleep .1
_664CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_664CLIENT_PID/./chat-client\" {print \$4}")
echo "66.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_665CLIENT_PID=$!
sleep .1
_665CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_665CLIENT_PID/./chat-client\" {print \$4}")
echo "66.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_666CLIENT_PID=$!
sleep .1
_666CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_666CLIENT_PID/./chat-client\" {print \$4}")
echo "66.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_667CLIENT_PID=$!
sleep .1
_667CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_667CLIENT_PID/./chat-client\" {print \$4}")
echo "66.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_668CLIENT_PID=$!
sleep .1
_668CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_668CLIENT_PID/./chat-client\" {print \$4}")
echo "66.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_669CLIENT_PID=$!
sleep .1
_669CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_669CLIENT_PID/./chat-client\" {print \$4}")
echo "66.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_670CLIENT_PID=$!
sleep .1
_670CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_670CLIENT_PID/./chat-client\" {print \$4}")
echo "67.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_671CLIENT_PID=$!
sleep .1
_671CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_671CLIENT_PID/./chat-client\" {print \$4}")
echo "67.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_672CLIENT_PID=$!
sleep .1
_672CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_672CLIENT_PID/./chat-client\" {print \$4}")
echo "67.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_673CLIENT_PID=$!
sleep .1
_673CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_673CLIENT_PID/./chat-client\" {print \$4}")
echo "67.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_674CLIENT_PID=$!
sleep .1
_674CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_674CLIENT_PID/./chat-client\" {print \$4}")
echo "67.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_675CLIENT_PID=$!
sleep .1
_675CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_675CLIENT_PID/./chat-client\" {print \$4}")
echo "67.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_676CLIENT_PID=$!
sleep .1
_676CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_676CLIENT_PID/./chat-client\" {print \$4}")
echo "67.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_677CLIENT_PID=$!
sleep .1
_677CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_677CLIENT_PID/./chat-client\" {print \$4}")
echo "67.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_678CLIENT_PID=$!
sleep .1
_678CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_678CLIENT_PID/./chat-client\" {print \$4}")
echo "67.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_679CLIENT_PID=$!
sleep .1
_679CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_679CLIENT_PID/./chat-client\" {print \$4}")
echo "67.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_680CLIENT_PID=$!
sleep .1
_680CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_680CLIENT_PID/./chat-client\" {print \$4}")
echo "68.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_681CLIENT_PID=$!
sleep .1
_681CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_681CLIENT_PID/./chat-client\" {print \$4}")
echo "68.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_682CLIENT_PID=$!
sleep .1
_682CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_682CLIENT_PID/./chat-client\" {print \$4}")
echo "68.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_683CLIENT_PID=$!
sleep .1
_683CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_683CLIENT_PID/./chat-client\" {print \$4}")
echo "68.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_684CLIENT_PID=$!
sleep .1
_684CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_684CLIENT_PID/./chat-client\" {print \$4}")
echo "68.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_685CLIENT_PID=$!
sleep .1
_685CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_685CLIENT_PID/./chat-client\" {print \$4}")
echo "68.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_686CLIENT_PID=$!
sleep .1
_686CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_686CLIENT_PID/./chat-client\" {print \$4}")
echo "68.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_687CLIENT_PID=$!
sleep .1
_687CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_687CLIENT_PID/./chat-client\" {print \$4}")
echo "68.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_688CLIENT_PID=$!
sleep .1
_688CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_688CLIENT_PID/./chat-client\" {print \$4}")
echo "68.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_689CLIENT_PID=$!
sleep .1
_689CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_689CLIENT_PID/./chat-client\" {print \$4}")
echo "68.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_690CLIENT_PID=$!
sleep .1
_690CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_690CLIENT_PID/./chat-client\" {print \$4}")
echo "69.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_691CLIENT_PID=$!
sleep .1
_691CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_691CLIENT_PID/./chat-client\" {print \$4}")
echo "69.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_692CLIENT_PID=$!
sleep .1
_692CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_692CLIENT_PID/./chat-client\" {print \$4}")
echo "69.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_693CLIENT_PID=$!
sleep .1
_693CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_693CLIENT_PID/./chat-client\" {print \$4}")
echo "69.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_694CLIENT_PID=$!
sleep .1
_694CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_694CLIENT_PID/./chat-client\" {print \$4}")
echo "69.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_695CLIENT_PID=$!
sleep .1
_695CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_695CLIENT_PID/./chat-client\" {print \$4}")
echo "69.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_696CLIENT_PID=$!
sleep .1
_696CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_696CLIENT_PID/./chat-client\" {print \$4}")
echo "69.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_697CLIENT_PID=$!
sleep .1
_697CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_697CLIENT_PID/./chat-client\" {print \$4}")
echo "69.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_698CLIENT_PID=$!
sleep .1
_698CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_698CLIENT_PID/./chat-client\" {print \$4}")
echo "69.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_699CLIENT_PID=$!
sleep .1
_699CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_699CLIENT_PID/./chat-client\" {print \$4}")
echo "69.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_700CLIENT_PID=$!
sleep .1
_700CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_700CLIENT_PID/./chat-client\" {print \$4}")
echo "70.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_701CLIENT_PID=$!
sleep .1
_701CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_701CLIENT_PID/./chat-client\" {print \$4}")
echo "70.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_702CLIENT_PID=$!
sleep .1
_702CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_702CLIENT_PID/./chat-client\" {print \$4}")
echo "70.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_703CLIENT_PID=$!
sleep .1
_703CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_703CLIENT_PID/./chat-client\" {print \$4}")
echo "70.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_704CLIENT_PID=$!
sleep .1
_704CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_704CLIENT_PID/./chat-client\" {print \$4}")
echo "70.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_705CLIENT_PID=$!
sleep .1
_705CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_705CLIENT_PID/./chat-client\" {print \$4}")
echo "70.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_706CLIENT_PID=$!
sleep .1
_706CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_706CLIENT_PID/./chat-client\" {print \$4}")
echo "70.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_707CLIENT_PID=$!
sleep .1
_707CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_707CLIENT_PID/./chat-client\" {print \$4}")
echo "70.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_708CLIENT_PID=$!
sleep .1
_708CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_708CLIENT_PID/./chat-client\" {print \$4}")
echo "70.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_709CLIENT_PID=$!
sleep .1
_709CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_709CLIENT_PID/./chat-client\" {print \$4}")
echo "70.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_710CLIENT_PID=$!
sleep .1
_710CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_710CLIENT_PID/./chat-client\" {print \$4}")
echo "71.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_711CLIENT_PID=$!
sleep .1
_711CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_711CLIENT_PID/./chat-client\" {print \$4}")
echo "71.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_712CLIENT_PID=$!
sleep .1
_712CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_712CLIENT_PID/./chat-client\" {print \$4}")
echo "71.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_713CLIENT_PID=$!
sleep .1
_713CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_713CLIENT_PID/./chat-client\" {print \$4}")
echo "71.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_714CLIENT_PID=$!
sleep .1
_714CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_714CLIENT_PID/./chat-client\" {print \$4}")
echo "71.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_715CLIENT_PID=$!
sleep .1
_715CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_715CLIENT_PID/./chat-client\" {print \$4}")
echo "71.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_716CLIENT_PID=$!
sleep .1
_716CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_716CLIENT_PID/./chat-client\" {print \$4}")
echo "71.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_717CLIENT_PID=$!
sleep .1
_717CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_717CLIENT_PID/./chat-client\" {print \$4}")
echo "71.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_718CLIENT_PID=$!
sleep .1
_718CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_718CLIENT_PID/./chat-client\" {print \$4}")
echo "71.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_719CLIENT_PID=$!
sleep .1
_719CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_719CLIENT_PID/./chat-client\" {print \$4}")
echo "71.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_720CLIENT_PID=$!
sleep .1
_720CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_720CLIENT_PID/./chat-client\" {print \$4}")
echo "72.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_721CLIENT_PID=$!
sleep .1
_721CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_721CLIENT_PID/./chat-client\" {print \$4}")
echo "72.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_722CLIENT_PID=$!
sleep .1
_722CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_722CLIENT_PID/./chat-client\" {print \$4}")
echo "72.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_723CLIENT_PID=$!
sleep .1
_723CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_723CLIENT_PID/./chat-client\" {print \$4}")
echo "72.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_724CLIENT_PID=$!
sleep .1
_724CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_724CLIENT_PID/./chat-client\" {print \$4}")
echo "72.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_725CLIENT_PID=$!
sleep .1
_725CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_725CLIENT_PID/./chat-client\" {print \$4}")
echo "72.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_726CLIENT_PID=$!
sleep .1
_726CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_726CLIENT_PID/./chat-client\" {print \$4}")
echo "72.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_727CLIENT_PID=$!
sleep .1
_727CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_727CLIENT_PID/./chat-client\" {print \$4}")
echo "72.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_728CLIENT_PID=$!
sleep .1
_728CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_728CLIENT_PID/./chat-client\" {print \$4}")
echo "72.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_729CLIENT_PID=$!
sleep .1
_729CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_729CLIENT_PID/./chat-client\" {print \$4}")
echo "72.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_730CLIENT_PID=$!
sleep .1
_730CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_730CLIENT_PID/./chat-client\" {print \$4}")
echo "73.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_731CLIENT_PID=$!
sleep .1
_731CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_731CLIENT_PID/./chat-client\" {print \$4}")
echo "73.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_732CLIENT_PID=$!
sleep .1
_732CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_732CLIENT_PID/./chat-client\" {print \$4}")
echo "73.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_733CLIENT_PID=$!
sleep .1
_733CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_733CLIENT_PID/./chat-client\" {print \$4}")
echo "73.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_734CLIENT_PID=$!
sleep .1
_734CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_734CLIENT_PID/./chat-client\" {print \$4}")
echo "73.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_735CLIENT_PID=$!
sleep .1
_735CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_735CLIENT_PID/./chat-client\" {print \$4}")
echo "73.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_736CLIENT_PID=$!
sleep .1
_736CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_736CLIENT_PID/./chat-client\" {print \$4}")
echo "73.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_737CLIENT_PID=$!
sleep .1
_737CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_737CLIENT_PID/./chat-client\" {print \$4}")
echo "73.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_738CLIENT_PID=$!
sleep .1
_738CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_738CLIENT_PID/./chat-client\" {print \$4}")
echo "73.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_739CLIENT_PID=$!
sleep .1
_739CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_739CLIENT_PID/./chat-client\" {print \$4}")
echo "73.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_740CLIENT_PID=$!
sleep .1
_740CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_740CLIENT_PID/./chat-client\" {print \$4}")
echo "74.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_741CLIENT_PID=$!
sleep .1
_741CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_741CLIENT_PID/./chat-client\" {print \$4}")
echo "74.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_742CLIENT_PID=$!
sleep .1
_742CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_742CLIENT_PID/./chat-client\" {print \$4}")
echo "74.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_743CLIENT_PID=$!
sleep .1
_743CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_743CLIENT_PID/./chat-client\" {print \$4}")
echo "74.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_744CLIENT_PID=$!
sleep .1
_744CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_744CLIENT_PID/./chat-client\" {print \$4}")
echo "74.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_745CLIENT_PID=$!
sleep .1
_745CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_745CLIENT_PID/./chat-client\" {print \$4}")
echo "74.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_746CLIENT_PID=$!
sleep .1
_746CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_746CLIENT_PID/./chat-client\" {print \$4}")
echo "74.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_747CLIENT_PID=$!
sleep .1
_747CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_747CLIENT_PID/./chat-client\" {print \$4}")
echo "74.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_748CLIENT_PID=$!
sleep .1
_748CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_748CLIENT_PID/./chat-client\" {print \$4}")
echo "74.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_749CLIENT_PID=$!
sleep .1
_749CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_749CLIENT_PID/./chat-client\" {print \$4}")
echo "74.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_750CLIENT_PID=$!
sleep .1
_750CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_750CLIENT_PID/./chat-client\" {print \$4}")
echo "75.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_751CLIENT_PID=$!
sleep .1
_751CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_751CLIENT_PID/./chat-client\" {print \$4}")
echo "75.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_752CLIENT_PID=$!
sleep .1
_752CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_752CLIENT_PID/./chat-client\" {print \$4}")
echo "75.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_753CLIENT_PID=$!
sleep .1
_753CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_753CLIENT_PID/./chat-client\" {print \$4}")
echo "75.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_754CLIENT_PID=$!
sleep .1
_754CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_754CLIENT_PID/./chat-client\" {print \$4}")
echo "75.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_755CLIENT_PID=$!
sleep .1
_755CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_755CLIENT_PID/./chat-client\" {print \$4}")
echo "75.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_756CLIENT_PID=$!
sleep .1
_756CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_756CLIENT_PID/./chat-client\" {print \$4}")
echo "75.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_757CLIENT_PID=$!
sleep .1
_757CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_757CLIENT_PID/./chat-client\" {print \$4}")
echo "75.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_758CLIENT_PID=$!
sleep .1
_758CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_758CLIENT_PID/./chat-client\" {print \$4}")
echo "75.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_759CLIENT_PID=$!
sleep .1
_759CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_759CLIENT_PID/./chat-client\" {print \$4}")
echo "75.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_760CLIENT_PID=$!
sleep .1
_760CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_760CLIENT_PID/./chat-client\" {print \$4}")
echo "76.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_761CLIENT_PID=$!
sleep .1
_761CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_761CLIENT_PID/./chat-client\" {print \$4}")
echo "76.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_762CLIENT_PID=$!
sleep .1
_762CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_762CLIENT_PID/./chat-client\" {print \$4}")
echo "76.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_763CLIENT_PID=$!
sleep .1
_763CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_763CLIENT_PID/./chat-client\" {print \$4}")
echo "76.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_764CLIENT_PID=$!
sleep .1
_764CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_764CLIENT_PID/./chat-client\" {print \$4}")
echo "76.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_765CLIENT_PID=$!
sleep .1
_765CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_765CLIENT_PID/./chat-client\" {print \$4}")
echo "76.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_766CLIENT_PID=$!
sleep .1
_766CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_766CLIENT_PID/./chat-client\" {print \$4}")
echo "76.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_767CLIENT_PID=$!
sleep .1
_767CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_767CLIENT_PID/./chat-client\" {print \$4}")
echo "76.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_768CLIENT_PID=$!
sleep .1
_768CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_768CLIENT_PID/./chat-client\" {print \$4}")
echo "76.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_769CLIENT_PID=$!
sleep .1
_769CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_769CLIENT_PID/./chat-client\" {print \$4}")
echo "76.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_770CLIENT_PID=$!
sleep .1
_770CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_770CLIENT_PID/./chat-client\" {print \$4}")
echo "77.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_771CLIENT_PID=$!
sleep .1
_771CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_771CLIENT_PID/./chat-client\" {print \$4}")
echo "77.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_772CLIENT_PID=$!
sleep .1
_772CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_772CLIENT_PID/./chat-client\" {print \$4}")
echo "77.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_773CLIENT_PID=$!
sleep .1
_773CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_773CLIENT_PID/./chat-client\" {print \$4}")
echo "77.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_774CLIENT_PID=$!
sleep .1
_774CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_774CLIENT_PID/./chat-client\" {print \$4}")
echo "77.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_775CLIENT_PID=$!
sleep .1
_775CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_775CLIENT_PID/./chat-client\" {print \$4}")
echo "77.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_776CLIENT_PID=$!
sleep .1
_776CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_776CLIENT_PID/./chat-client\" {print \$4}")
echo "77.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_777CLIENT_PID=$!
sleep .1
_777CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_777CLIENT_PID/./chat-client\" {print \$4}")
echo "77.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_778CLIENT_PID=$!
sleep .1
_778CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_778CLIENT_PID/./chat-client\" {print \$4}")
echo "77.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_779CLIENT_PID=$!
sleep .1
_779CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_779CLIENT_PID/./chat-client\" {print \$4}")
echo "77.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_780CLIENT_PID=$!
sleep .1
_780CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_780CLIENT_PID/./chat-client\" {print \$4}")
echo "78.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_781CLIENT_PID=$!
sleep .1
_781CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_781CLIENT_PID/./chat-client\" {print \$4}")
echo "78.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_782CLIENT_PID=$!
sleep .1
_782CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_782CLIENT_PID/./chat-client\" {print \$4}")
echo "78.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_783CLIENT_PID=$!
sleep .1
_783CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_783CLIENT_PID/./chat-client\" {print \$4}")
echo "78.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_784CLIENT_PID=$!
sleep .1
_784CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_784CLIENT_PID/./chat-client\" {print \$4}")
echo "78.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_785CLIENT_PID=$!
sleep .1
_785CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_785CLIENT_PID/./chat-client\" {print \$4}")
echo "78.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_786CLIENT_PID=$!
sleep .1
_786CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_786CLIENT_PID/./chat-client\" {print \$4}")
echo "78.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_787CLIENT_PID=$!
sleep .1
_787CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_787CLIENT_PID/./chat-client\" {print \$4}")
echo "78.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_788CLIENT_PID=$!
sleep .1
_788CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_788CLIENT_PID/./chat-client\" {print \$4}")
echo "78.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_789CLIENT_PID=$!
sleep .1
_789CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_789CLIENT_PID/./chat-client\" {print \$4}")
echo "78.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_790CLIENT_PID=$!
sleep .1
_790CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_790CLIENT_PID/./chat-client\" {print \$4}")
echo "79.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_791CLIENT_PID=$!
sleep .1
_791CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_791CLIENT_PID/./chat-client\" {print \$4}")
echo "79.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_792CLIENT_PID=$!
sleep .1
_792CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_792CLIENT_PID/./chat-client\" {print \$4}")
echo "79.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_793CLIENT_PID=$!
sleep .1
_793CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_793CLIENT_PID/./chat-client\" {print \$4}")
echo "79.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_794CLIENT_PID=$!
sleep .1
_794CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_794CLIENT_PID/./chat-client\" {print \$4}")
echo "79.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_795CLIENT_PID=$!
sleep .1
_795CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_795CLIENT_PID/./chat-client\" {print \$4}")
echo "79.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_796CLIENT_PID=$!
sleep .1
_796CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_796CLIENT_PID/./chat-client\" {print \$4}")
echo "79.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_797CLIENT_PID=$!
sleep .1
_797CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_797CLIENT_PID/./chat-client\" {print \$4}")
echo "79.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_798CLIENT_PID=$!
sleep .1
_798CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_798CLIENT_PID/./chat-client\" {print \$4}")
echo "79.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_799CLIENT_PID=$!
sleep .1
_799CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_799CLIENT_PID/./chat-client\" {print \$4}")
echo "79.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_800CLIENT_PID=$!
sleep .1
_800CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_800CLIENT_PID/./chat-client\" {print \$4}")
echo "80.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_801CLIENT_PID=$!
sleep .1
_801CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_801CLIENT_PID/./chat-client\" {print \$4}")
echo "80.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_802CLIENT_PID=$!
sleep .1
_802CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_802CLIENT_PID/./chat-client\" {print \$4}")
echo "80.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_803CLIENT_PID=$!
sleep .1
_803CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_803CLIENT_PID/./chat-client\" {print \$4}")
echo "80.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_804CLIENT_PID=$!
sleep .1
_804CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_804CLIENT_PID/./chat-client\" {print \$4}")
echo "80.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_805CLIENT_PID=$!
sleep .1
_805CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_805CLIENT_PID/./chat-client\" {print \$4}")
echo "80.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_806CLIENT_PID=$!
sleep .1
_806CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_806CLIENT_PID/./chat-client\" {print \$4}")
echo "80.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_807CLIENT_PID=$!
sleep .1
_807CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_807CLIENT_PID/./chat-client\" {print \$4}")
echo "80.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_808CLIENT_PID=$!
sleep .1
_808CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_808CLIENT_PID/./chat-client\" {print \$4}")
echo "80.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_809CLIENT_PID=$!
sleep .1
_809CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_809CLIENT_PID/./chat-client\" {print \$4}")
echo "80.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_810CLIENT_PID=$!
sleep .1
_810CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_810CLIENT_PID/./chat-client\" {print \$4}")
echo "81.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_811CLIENT_PID=$!
sleep .1
_811CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_811CLIENT_PID/./chat-client\" {print \$4}")
echo "81.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_812CLIENT_PID=$!
sleep .1
_812CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_812CLIENT_PID/./chat-client\" {print \$4}")
echo "81.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_813CLIENT_PID=$!
sleep .1
_813CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_813CLIENT_PID/./chat-client\" {print \$4}")
echo "81.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_814CLIENT_PID=$!
sleep .1
_814CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_814CLIENT_PID/./chat-client\" {print \$4}")
echo "81.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_815CLIENT_PID=$!
sleep .1
_815CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_815CLIENT_PID/./chat-client\" {print \$4}")
echo "81.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_816CLIENT_PID=$!
sleep .1
_816CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_816CLIENT_PID/./chat-client\" {print \$4}")
echo "81.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_817CLIENT_PID=$!
sleep .1
_817CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_817CLIENT_PID/./chat-client\" {print \$4}")
echo "81.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_818CLIENT_PID=$!
sleep .1
_818CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_818CLIENT_PID/./chat-client\" {print \$4}")
echo "81.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_819CLIENT_PID=$!
sleep .1
_819CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_819CLIENT_PID/./chat-client\" {print \$4}")
echo "81.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_820CLIENT_PID=$!
sleep .1
_820CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_820CLIENT_PID/./chat-client\" {print \$4}")
echo "82.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_821CLIENT_PID=$!
sleep .1
_821CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_821CLIENT_PID/./chat-client\" {print \$4}")
echo "82.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_822CLIENT_PID=$!
sleep .1
_822CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_822CLIENT_PID/./chat-client\" {print \$4}")
echo "82.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_823CLIENT_PID=$!
sleep .1
_823CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_823CLIENT_PID/./chat-client\" {print \$4}")
echo "82.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_824CLIENT_PID=$!
sleep .1
_824CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_824CLIENT_PID/./chat-client\" {print \$4}")
echo "82.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_825CLIENT_PID=$!
sleep .1
_825CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_825CLIENT_PID/./chat-client\" {print \$4}")
echo "82.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_826CLIENT_PID=$!
sleep .1
_826CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_826CLIENT_PID/./chat-client\" {print \$4}")
echo "82.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_827CLIENT_PID=$!
sleep .1
_827CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_827CLIENT_PID/./chat-client\" {print \$4}")
echo "82.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_828CLIENT_PID=$!
sleep .1
_828CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_828CLIENT_PID/./chat-client\" {print \$4}")
echo "82.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_829CLIENT_PID=$!
sleep .1
_829CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_829CLIENT_PID/./chat-client\" {print \$4}")
echo "82.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_830CLIENT_PID=$!
sleep .1
_830CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_830CLIENT_PID/./chat-client\" {print \$4}")
echo "83.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_831CLIENT_PID=$!
sleep .1
_831CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_831CLIENT_PID/./chat-client\" {print \$4}")
echo "83.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_832CLIENT_PID=$!
sleep .1
_832CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_832CLIENT_PID/./chat-client\" {print \$4}")
echo "83.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_833CLIENT_PID=$!
sleep .1
_833CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_833CLIENT_PID/./chat-client\" {print \$4}")
echo "83.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_834CLIENT_PID=$!
sleep .1
_834CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_834CLIENT_PID/./chat-client\" {print \$4}")
echo "83.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_835CLIENT_PID=$!
sleep .1
_835CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_835CLIENT_PID/./chat-client\" {print \$4}")
echo "83.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_836CLIENT_PID=$!
sleep .1
_836CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_836CLIENT_PID/./chat-client\" {print \$4}")
echo "83.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_837CLIENT_PID=$!
sleep .1
_837CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_837CLIENT_PID/./chat-client\" {print \$4}")
echo "83.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_838CLIENT_PID=$!
sleep .1
_838CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_838CLIENT_PID/./chat-client\" {print \$4}")
echo "83.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_839CLIENT_PID=$!
sleep .1
_839CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_839CLIENT_PID/./chat-client\" {print \$4}")
echo "83.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_840CLIENT_PID=$!
sleep .1
_840CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_840CLIENT_PID/./chat-client\" {print \$4}")
echo "84.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_841CLIENT_PID=$!
sleep .1
_841CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_841CLIENT_PID/./chat-client\" {print \$4}")
echo "84.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_842CLIENT_PID=$!
sleep .1
_842CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_842CLIENT_PID/./chat-client\" {print \$4}")
echo "84.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_843CLIENT_PID=$!
sleep .1
_843CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_843CLIENT_PID/./chat-client\" {print \$4}")
echo "84.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_844CLIENT_PID=$!
sleep .1
_844CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_844CLIENT_PID/./chat-client\" {print \$4}")
echo "84.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_845CLIENT_PID=$!
sleep .1
_845CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_845CLIENT_PID/./chat-client\" {print \$4}")
echo "84.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_846CLIENT_PID=$!
sleep .1
_846CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_846CLIENT_PID/./chat-client\" {print \$4}")
echo "84.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_847CLIENT_PID=$!
sleep .1
_847CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_847CLIENT_PID/./chat-client\" {print \$4}")
echo "84.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_848CLIENT_PID=$!
sleep .1
_848CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_848CLIENT_PID/./chat-client\" {print \$4}")
echo "84.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_849CLIENT_PID=$!
sleep .1
_849CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_849CLIENT_PID/./chat-client\" {print \$4}")
echo "84.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_850CLIENT_PID=$!
sleep .1
_850CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_850CLIENT_PID/./chat-client\" {print \$4}")
echo "85.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_851CLIENT_PID=$!
sleep .1
_851CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_851CLIENT_PID/./chat-client\" {print \$4}")
echo "85.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_852CLIENT_PID=$!
sleep .1
_852CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_852CLIENT_PID/./chat-client\" {print \$4}")
echo "85.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_853CLIENT_PID=$!
sleep .1
_853CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_853CLIENT_PID/./chat-client\" {print \$4}")
echo "85.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_854CLIENT_PID=$!
sleep .1
_854CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_854CLIENT_PID/./chat-client\" {print \$4}")
echo "85.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_855CLIENT_PID=$!
sleep .1
_855CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_855CLIENT_PID/./chat-client\" {print \$4}")
echo "85.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_856CLIENT_PID=$!
sleep .1
_856CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_856CLIENT_PID/./chat-client\" {print \$4}")
echo "85.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_857CLIENT_PID=$!
sleep .1
_857CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_857CLIENT_PID/./chat-client\" {print \$4}")
echo "85.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_858CLIENT_PID=$!
sleep .1
_858CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_858CLIENT_PID/./chat-client\" {print \$4}")
echo "85.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_859CLIENT_PID=$!
sleep .1
_859CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_859CLIENT_PID/./chat-client\" {print \$4}")
echo "85.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_860CLIENT_PID=$!
sleep .1
_860CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_860CLIENT_PID/./chat-client\" {print \$4}")
echo "86.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_861CLIENT_PID=$!
sleep .1
_861CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_861CLIENT_PID/./chat-client\" {print \$4}")
echo "86.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_862CLIENT_PID=$!
sleep .1
_862CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_862CLIENT_PID/./chat-client\" {print \$4}")
echo "86.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_863CLIENT_PID=$!
sleep .1
_863CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_863CLIENT_PID/./chat-client\" {print \$4}")
echo "86.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_864CLIENT_PID=$!
sleep .1
_864CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_864CLIENT_PID/./chat-client\" {print \$4}")
echo "86.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_865CLIENT_PID=$!
sleep .1
_865CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_865CLIENT_PID/./chat-client\" {print \$4}")
echo "86.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_866CLIENT_PID=$!
sleep .1
_866CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_866CLIENT_PID/./chat-client\" {print \$4}")
echo "86.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_867CLIENT_PID=$!
sleep .1
_867CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_867CLIENT_PID/./chat-client\" {print \$4}")
echo "86.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_868CLIENT_PID=$!
sleep .1
_868CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_868CLIENT_PID/./chat-client\" {print \$4}")
echo "86.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_869CLIENT_PID=$!
sleep .1
_869CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_869CLIENT_PID/./chat-client\" {print \$4}")
echo "86.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_870CLIENT_PID=$!
sleep .1
_870CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_870CLIENT_PID/./chat-client\" {print \$4}")
echo "87.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_871CLIENT_PID=$!
sleep .1
_871CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_871CLIENT_PID/./chat-client\" {print \$4}")
echo "87.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_872CLIENT_PID=$!
sleep .1
_872CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_872CLIENT_PID/./chat-client\" {print \$4}")
echo "87.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_873CLIENT_PID=$!
sleep .1
_873CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_873CLIENT_PID/./chat-client\" {print \$4}")
echo "87.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_874CLIENT_PID=$!
sleep .1
_874CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_874CLIENT_PID/./chat-client\" {print \$4}")
echo "87.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_875CLIENT_PID=$!
sleep .1
_875CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_875CLIENT_PID/./chat-client\" {print \$4}")
echo "87.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_876CLIENT_PID=$!
sleep .1
_876CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_876CLIENT_PID/./chat-client\" {print \$4}")
echo "87.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_877CLIENT_PID=$!
sleep .1
_877CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_877CLIENT_PID/./chat-client\" {print \$4}")
echo "87.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_878CLIENT_PID=$!
sleep .1
_878CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_878CLIENT_PID/./chat-client\" {print \$4}")
echo "87.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_879CLIENT_PID=$!
sleep .1
_879CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_879CLIENT_PID/./chat-client\" {print \$4}")
echo "87.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_880CLIENT_PID=$!
sleep .1
_880CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_880CLIENT_PID/./chat-client\" {print \$4}")
echo "88.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_881CLIENT_PID=$!
sleep .1
_881CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_881CLIENT_PID/./chat-client\" {print \$4}")
echo "88.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_882CLIENT_PID=$!
sleep .1
_882CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_882CLIENT_PID/./chat-client\" {print \$4}")
echo "88.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_883CLIENT_PID=$!
sleep .1
_883CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_883CLIENT_PID/./chat-client\" {print \$4}")
echo "88.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_884CLIENT_PID=$!
sleep .1
_884CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_884CLIENT_PID/./chat-client\" {print \$4}")
echo "88.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_885CLIENT_PID=$!
sleep .1
_885CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_885CLIENT_PID/./chat-client\" {print \$4}")
echo "88.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_886CLIENT_PID=$!
sleep .1
_886CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_886CLIENT_PID/./chat-client\" {print \$4}")
echo "88.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_887CLIENT_PID=$!
sleep .1
_887CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_887CLIENT_PID/./chat-client\" {print \$4}")
echo "88.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_888CLIENT_PID=$!
sleep .1
_888CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_888CLIENT_PID/./chat-client\" {print \$4}")
echo "88.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_889CLIENT_PID=$!
sleep .1
_889CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_889CLIENT_PID/./chat-client\" {print \$4}")
echo "88.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_890CLIENT_PID=$!
sleep .1
_890CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_890CLIENT_PID/./chat-client\" {print \$4}")
echo "89.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_891CLIENT_PID=$!
sleep .1
_891CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_891CLIENT_PID/./chat-client\" {print \$4}")
echo "89.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_892CLIENT_PID=$!
sleep .1
_892CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_892CLIENT_PID/./chat-client\" {print \$4}")
echo "89.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_893CLIENT_PID=$!
sleep .1
_893CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_893CLIENT_PID/./chat-client\" {print \$4}")
echo "89.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_894CLIENT_PID=$!
sleep .1
_894CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_894CLIENT_PID/./chat-client\" {print \$4}")
echo "89.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_895CLIENT_PID=$!
sleep .1
_895CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_895CLIENT_PID/./chat-client\" {print \$4}")
echo "89.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_896CLIENT_PID=$!
sleep .1
_896CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_896CLIENT_PID/./chat-client\" {print \$4}")
echo "89.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_897CLIENT_PID=$!
sleep .1
_897CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_897CLIENT_PID/./chat-client\" {print \$4}")
echo "89.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_898CLIENT_PID=$!
sleep .1
_898CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_898CLIENT_PID/./chat-client\" {print \$4}")
echo "89.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_899CLIENT_PID=$!
sleep .1
_899CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_899CLIENT_PID/./chat-client\" {print \$4}")
echo "89.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_900CLIENT_PID=$!
sleep .1
_900CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_900CLIENT_PID/./chat-client\" {print \$4}")
echo "90.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_901CLIENT_PID=$!
sleep .1
_901CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_901CLIENT_PID/./chat-client\" {print \$4}")
echo "90.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_902CLIENT_PID=$!
sleep .1
_902CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_902CLIENT_PID/./chat-client\" {print \$4}")
echo "90.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_903CLIENT_PID=$!
sleep .1
_903CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_903CLIENT_PID/./chat-client\" {print \$4}")
echo "90.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_904CLIENT_PID=$!
sleep .1
_904CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_904CLIENT_PID/./chat-client\" {print \$4}")
echo "90.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_905CLIENT_PID=$!
sleep .1
_905CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_905CLIENT_PID/./chat-client\" {print \$4}")
echo "90.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_906CLIENT_PID=$!
sleep .1
_906CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_906CLIENT_PID/./chat-client\" {print \$4}")
echo "90.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_907CLIENT_PID=$!
sleep .1
_907CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_907CLIENT_PID/./chat-client\" {print \$4}")
echo "90.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_908CLIENT_PID=$!
sleep .1
_908CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_908CLIENT_PID/./chat-client\" {print \$4}")
echo "90.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_909CLIENT_PID=$!
sleep .1
_909CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_909CLIENT_PID/./chat-client\" {print \$4}")
echo "90.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_910CLIENT_PID=$!
sleep .1
_910CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_910CLIENT_PID/./chat-client\" {print \$4}")
echo "91.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_911CLIENT_PID=$!
sleep .1
_911CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_911CLIENT_PID/./chat-client\" {print \$4}")
echo "91.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_912CLIENT_PID=$!
sleep .1
_912CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_912CLIENT_PID/./chat-client\" {print \$4}")
echo "91.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_913CLIENT_PID=$!
sleep .1
_913CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_913CLIENT_PID/./chat-client\" {print \$4}")
echo "91.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_914CLIENT_PID=$!
sleep .1
_914CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_914CLIENT_PID/./chat-client\" {print \$4}")
echo "91.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_915CLIENT_PID=$!
sleep .1
_915CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_915CLIENT_PID/./chat-client\" {print \$4}")
echo "91.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_916CLIENT_PID=$!
sleep .1
_916CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_916CLIENT_PID/./chat-client\" {print \$4}")
echo "91.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_917CLIENT_PID=$!
sleep .1
_917CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_917CLIENT_PID/./chat-client\" {print \$4}")
echo "91.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_918CLIENT_PID=$!
sleep .1
_918CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_918CLIENT_PID/./chat-client\" {print \$4}")
echo "91.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_919CLIENT_PID=$!
sleep .1
_919CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_919CLIENT_PID/./chat-client\" {print \$4}")
echo "91.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_920CLIENT_PID=$!
sleep .1
_920CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_920CLIENT_PID/./chat-client\" {print \$4}")
echo "92.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_921CLIENT_PID=$!
sleep .1
_921CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_921CLIENT_PID/./chat-client\" {print \$4}")
echo "92.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_922CLIENT_PID=$!
sleep .1
_922CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_922CLIENT_PID/./chat-client\" {print \$4}")
echo "92.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_923CLIENT_PID=$!
sleep .1
_923CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_923CLIENT_PID/./chat-client\" {print \$4}")
echo "92.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_924CLIENT_PID=$!
sleep .1
_924CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_924CLIENT_PID/./chat-client\" {print \$4}")
echo "92.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_925CLIENT_PID=$!
sleep .1
_925CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_925CLIENT_PID/./chat-client\" {print \$4}")
echo "92.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_926CLIENT_PID=$!
sleep .1
_926CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_926CLIENT_PID/./chat-client\" {print \$4}")
echo "92.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_927CLIENT_PID=$!
sleep .1
_927CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_927CLIENT_PID/./chat-client\" {print \$4}")
echo "92.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_928CLIENT_PID=$!
sleep .1
_928CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_928CLIENT_PID/./chat-client\" {print \$4}")
echo "92.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_929CLIENT_PID=$!
sleep .1
_929CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_929CLIENT_PID/./chat-client\" {print \$4}")
echo "92.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_930CLIENT_PID=$!
sleep .1
_930CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_930CLIENT_PID/./chat-client\" {print \$4}")
echo "93.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_931CLIENT_PID=$!
sleep .1
_931CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_931CLIENT_PID/./chat-client\" {print \$4}")
echo "93.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_932CLIENT_PID=$!
sleep .1
_932CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_932CLIENT_PID/./chat-client\" {print \$4}")
echo "93.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_933CLIENT_PID=$!
sleep .1
_933CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_933CLIENT_PID/./chat-client\" {print \$4}")
echo "93.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_934CLIENT_PID=$!
sleep .1
_934CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_934CLIENT_PID/./chat-client\" {print \$4}")
echo "93.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_935CLIENT_PID=$!
sleep .1
_935CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_935CLIENT_PID/./chat-client\" {print \$4}")
echo "93.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_936CLIENT_PID=$!
sleep .1
_936CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_936CLIENT_PID/./chat-client\" {print \$4}")
echo "93.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_937CLIENT_PID=$!
sleep .1
_937CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_937CLIENT_PID/./chat-client\" {print \$4}")
echo "93.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_938CLIENT_PID=$!
sleep .1
_938CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_938CLIENT_PID/./chat-client\" {print \$4}")
echo "93.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_939CLIENT_PID=$!
sleep .1
_939CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_939CLIENT_PID/./chat-client\" {print \$4}")
echo "93.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_940CLIENT_PID=$!
sleep .1
_940CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_940CLIENT_PID/./chat-client\" {print \$4}")
echo "94.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_941CLIENT_PID=$!
sleep .1
_941CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_941CLIENT_PID/./chat-client\" {print \$4}")
echo "94.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_942CLIENT_PID=$!
sleep .1
_942CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_942CLIENT_PID/./chat-client\" {print \$4}")
echo "94.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_943CLIENT_PID=$!
sleep .1
_943CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_943CLIENT_PID/./chat-client\" {print \$4}")
echo "94.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_944CLIENT_PID=$!
sleep .1
_944CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_944CLIENT_PID/./chat-client\" {print \$4}")
echo "94.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_945CLIENT_PID=$!
sleep .1
_945CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_945CLIENT_PID/./chat-client\" {print \$4}")
echo "94.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_946CLIENT_PID=$!
sleep .1
_946CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_946CLIENT_PID/./chat-client\" {print \$4}")
echo "94.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_947CLIENT_PID=$!
sleep .1
_947CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_947CLIENT_PID/./chat-client\" {print \$4}")
echo "94.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_948CLIENT_PID=$!
sleep .1
_948CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_948CLIENT_PID/./chat-client\" {print \$4}")
echo "94.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_949CLIENT_PID=$!
sleep .1
_949CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_949CLIENT_PID/./chat-client\" {print \$4}")
echo "94.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_950CLIENT_PID=$!
sleep .1
_950CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_950CLIENT_PID/./chat-client\" {print \$4}")
echo "95.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_951CLIENT_PID=$!
sleep .1
_951CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_951CLIENT_PID/./chat-client\" {print \$4}")
echo "95.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_952CLIENT_PID=$!
sleep .1
_952CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_952CLIENT_PID/./chat-client\" {print \$4}")
echo "95.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_953CLIENT_PID=$!
sleep .1
_953CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_953CLIENT_PID/./chat-client\" {print \$4}")
echo "95.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_954CLIENT_PID=$!
sleep .1
_954CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_954CLIENT_PID/./chat-client\" {print \$4}")
echo "95.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_955CLIENT_PID=$!
sleep .1
_955CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_955CLIENT_PID/./chat-client\" {print \$4}")
echo "95.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_956CLIENT_PID=$!
sleep .1
_956CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_956CLIENT_PID/./chat-client\" {print \$4}")
echo "95.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_957CLIENT_PID=$!
sleep .1
_957CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_957CLIENT_PID/./chat-client\" {print \$4}")
echo "95.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_958CLIENT_PID=$!
sleep .1
_958CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_958CLIENT_PID/./chat-client\" {print \$4}")
echo "95.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_959CLIENT_PID=$!
sleep .1
_959CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_959CLIENT_PID/./chat-client\" {print \$4}")
echo "95.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_960CLIENT_PID=$!
sleep .1
_960CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_960CLIENT_PID/./chat-client\" {print \$4}")
echo "96.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_961CLIENT_PID=$!
sleep .1
_961CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_961CLIENT_PID/./chat-client\" {print \$4}")
echo "96.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_962CLIENT_PID=$!
sleep .1
_962CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_962CLIENT_PID/./chat-client\" {print \$4}")
echo "96.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_963CLIENT_PID=$!
sleep .1
_963CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_963CLIENT_PID/./chat-client\" {print \$4}")
echo "96.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_964CLIENT_PID=$!
sleep .1
_964CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_964CLIENT_PID/./chat-client\" {print \$4}")
echo "96.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_965CLIENT_PID=$!
sleep .1
_965CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_965CLIENT_PID/./chat-client\" {print \$4}")
echo "96.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_966CLIENT_PID=$!
sleep .1
_966CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_966CLIENT_PID/./chat-client\" {print \$4}")
echo "96.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_967CLIENT_PID=$!
sleep .1
_967CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_967CLIENT_PID/./chat-client\" {print \$4}")
echo "96.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_968CLIENT_PID=$!
sleep .1
_968CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_968CLIENT_PID/./chat-client\" {print \$4}")
echo "96.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_969CLIENT_PID=$!
sleep .1
_969CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_969CLIENT_PID/./chat-client\" {print \$4}")
echo "96.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_970CLIENT_PID=$!
sleep .1
_970CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_970CLIENT_PID/./chat-client\" {print \$4}")
echo "97.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_971CLIENT_PID=$!
sleep .1
_971CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_971CLIENT_PID/./chat-client\" {print \$4}")
echo "97.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_972CLIENT_PID=$!
sleep .1
_972CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_972CLIENT_PID/./chat-client\" {print \$4}")
echo "97.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_973CLIENT_PID=$!
sleep .1
_973CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_973CLIENT_PID/./chat-client\" {print \$4}")
echo "97.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_974CLIENT_PID=$!
sleep .1
_974CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_974CLIENT_PID/./chat-client\" {print \$4}")
echo "97.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_975CLIENT_PID=$!
sleep .1
_975CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_975CLIENT_PID/./chat-client\" {print \$4}")
echo "97.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_976CLIENT_PID=$!
sleep .1
_976CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_976CLIENT_PID/./chat-client\" {print \$4}")
echo "97.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_977CLIENT_PID=$!
sleep .1
_977CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_977CLIENT_PID/./chat-client\" {print \$4}")
echo "97.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_978CLIENT_PID=$!
sleep .1
_978CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_978CLIENT_PID/./chat-client\" {print \$4}")
echo "97.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_979CLIENT_PID=$!
sleep .1
_979CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_979CLIENT_PID/./chat-client\" {print \$4}")
echo "97.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_980CLIENT_PID=$!
sleep .1
_980CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_980CLIENT_PID/./chat-client\" {print \$4}")
echo "98.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_981CLIENT_PID=$!
sleep .1
_981CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_981CLIENT_PID/./chat-client\" {print \$4}")
echo "98.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_982CLIENT_PID=$!
sleep .1
_982CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_982CLIENT_PID/./chat-client\" {print \$4}")
echo "98.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_983CLIENT_PID=$!
sleep .1
_983CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_983CLIENT_PID/./chat-client\" {print \$4}")
echo "98.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_984CLIENT_PID=$!
sleep .1
_984CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_984CLIENT_PID/./chat-client\" {print \$4}")
echo "98.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_985CLIENT_PID=$!
sleep .1
_985CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_985CLIENT_PID/./chat-client\" {print \$4}")
echo "98.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_986CLIENT_PID=$!
sleep .1
_986CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_986CLIENT_PID/./chat-client\" {print \$4}")
echo "98.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_987CLIENT_PID=$!
sleep .1
_987CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_987CLIENT_PID/./chat-client\" {print \$4}")
echo "98.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_988CLIENT_PID=$!
sleep .1
_988CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_988CLIENT_PID/./chat-client\" {print \$4}")
echo "98.8%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_989CLIENT_PID=$!
sleep .1
_989CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_989CLIENT_PID/./chat-client\" {print \$4}")
echo "98.9%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_990CLIENT_PID=$!
sleep .1
_990CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_990CLIENT_PID/./chat-client\" {print \$4}")
echo "99.0%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_991CLIENT_PID=$!
sleep .1
_991CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_991CLIENT_PID/./chat-client\" {print \$4}")
echo "99.1%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_992CLIENT_PID=$!
sleep .1
_992CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_992CLIENT_PID/./chat-client\" {print \$4}")
echo "99.2%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_993CLIENT_PID=$!
sleep .1
_993CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_993CLIENT_PID/./chat-client\" {print \$4}")
echo "99.3%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_994CLIENT_PID=$!
sleep .1
_994CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_994CLIENT_PID/./chat-client\" {print \$4}")
echo "99.4%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_995CLIENT_PID=$!
sleep .1
_995CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_995CLIENT_PID/./chat-client\" {print \$4}")
echo "99.5%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_996CLIENT_PID=$!
sleep .1
_996CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_996CLIENT_PID/./chat-client\" {print \$4}")
echo "99.6%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_997CLIENT_PID=$!
sleep .1
_997CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_997CLIENT_PID/./chat-client\" {print \$4}")
echo "99.7%"


(echo Test; sleep 999) | ./chat-client localhost 1234 >/dev/null 2>/dev/null &
_998CLIENT_PID=$!
sleep .1
_998CLIENT_IPPORT=$(netstat -np 2>/dev/null | awk "\$7 == \"$_998CLIENT_PID/./chat-client\" {print \$4}")
echo "99.8"

echo "100%"

kill $SERVER_PID
wait $SERVER_PID 2>/dev/null || true

echo -ne "Checking output format...\t"
if diff chat-client.out - <<EOF
$RCLIENT_IPPORT joined.
$_0CLIENT_IPPORT joined.
$_0CLIENT_IPPORT Test
$_1CLIENT_IPPORT joined.
$_1CLIENT_IPPORT Test
$_2CLIENT_IPPORT joined.
$_2CLIENT_IPPORT Test
$_3CLIENT_IPPORT joined.
$_3CLIENT_IPPORT Test
$_4CLIENT_IPPORT joined.
$_4CLIENT_IPPORT Test
$_5CLIENT_IPPORT joined.
$_5CLIENT_IPPORT Test
$_6CLIENT_IPPORT joined.
$_6CLIENT_IPPORT Test
$_7CLIENT_IPPORT joined.
$_7CLIENT_IPPORT Test
$_8CLIENT_IPPORT joined.
$_8CLIENT_IPPORT Test
$_9CLIENT_IPPORT joined.
$_9CLIENT_IPPORT Test
$_10CLIENT_IPPORT joined.
$_10CLIENT_IPPORT Test
$_11CLIENT_IPPORT joined.
$_11CLIENT_IPPORT Test
$_12CLIENT_IPPORT joined.
$_12CLIENT_IPPORT Test
$_13CLIENT_IPPORT joined.
$_13CLIENT_IPPORT Test
$_14CLIENT_IPPORT joined.
$_14CLIENT_IPPORT Test
$_15CLIENT_IPPORT joined.
$_15CLIENT_IPPORT Test
$_16CLIENT_IPPORT joined.
$_16CLIENT_IPPORT Test
$_17CLIENT_IPPORT joined.
$_17CLIENT_IPPORT Test
$_18CLIENT_IPPORT joined.
$_18CLIENT_IPPORT Test
$_19CLIENT_IPPORT joined.
$_19CLIENT_IPPORT Test
$_20CLIENT_IPPORT joined.
$_20CLIENT_IPPORT Test
$_21CLIENT_IPPORT joined.
$_21CLIENT_IPPORT Test
$_22CLIENT_IPPORT joined.
$_22CLIENT_IPPORT Test
$_23CLIENT_IPPORT joined.
$_23CLIENT_IPPORT Test
$_24CLIENT_IPPORT joined.
$_24CLIENT_IPPORT Test
$_25CLIENT_IPPORT joined.
$_25CLIENT_IPPORT Test
$_26CLIENT_IPPORT joined.
$_26CLIENT_IPPORT Test
$_27CLIENT_IPPORT joined.
$_27CLIENT_IPPORT Test
$_28CLIENT_IPPORT joined.
$_28CLIENT_IPPORT Test
$_29CLIENT_IPPORT joined.
$_29CLIENT_IPPORT Test
$_30CLIENT_IPPORT joined.
$_30CLIENT_IPPORT Test
$_31CLIENT_IPPORT joined.
$_31CLIENT_IPPORT Test
$_32CLIENT_IPPORT joined.
$_32CLIENT_IPPORT Test
$_33CLIENT_IPPORT joined.
$_33CLIENT_IPPORT Test
$_34CLIENT_IPPORT joined.
$_34CLIENT_IPPORT Test
$_35CLIENT_IPPORT joined.
$_35CLIENT_IPPORT Test
$_36CLIENT_IPPORT joined.
$_36CLIENT_IPPORT Test
$_37CLIENT_IPPORT joined.
$_37CLIENT_IPPORT Test
$_38CLIENT_IPPORT joined.
$_38CLIENT_IPPORT Test
$_39CLIENT_IPPORT joined.
$_39CLIENT_IPPORT Test
$_40CLIENT_IPPORT joined.
$_40CLIENT_IPPORT Test
$_41CLIENT_IPPORT joined.
$_41CLIENT_IPPORT Test
$_42CLIENT_IPPORT joined.
$_42CLIENT_IPPORT Test
$_43CLIENT_IPPORT joined.
$_43CLIENT_IPPORT Test
$_44CLIENT_IPPORT joined.
$_44CLIENT_IPPORT Test
$_45CLIENT_IPPORT joined.
$_45CLIENT_IPPORT Test
$_46CLIENT_IPPORT joined.
$_46CLIENT_IPPORT Test
$_47CLIENT_IPPORT joined.
$_47CLIENT_IPPORT Test
$_48CLIENT_IPPORT joined.
$_48CLIENT_IPPORT Test
$_49CLIENT_IPPORT joined.
$_49CLIENT_IPPORT Test
$_50CLIENT_IPPORT joined.
$_50CLIENT_IPPORT Test
$_51CLIENT_IPPORT joined.
$_51CLIENT_IPPORT Test
$_52CLIENT_IPPORT joined.
$_52CLIENT_IPPORT Test
$_53CLIENT_IPPORT joined.
$_53CLIENT_IPPORT Test
$_54CLIENT_IPPORT joined.
$_54CLIENT_IPPORT Test
$_55CLIENT_IPPORT joined.
$_55CLIENT_IPPORT Test
$_56CLIENT_IPPORT joined.
$_56CLIENT_IPPORT Test
$_57CLIENT_IPPORT joined.
$_57CLIENT_IPPORT Test
$_58CLIENT_IPPORT joined.
$_58CLIENT_IPPORT Test
$_59CLIENT_IPPORT joined.
$_59CLIENT_IPPORT Test
$_60CLIENT_IPPORT joined.
$_60CLIENT_IPPORT Test
$_61CLIENT_IPPORT joined.
$_61CLIENT_IPPORT Test
$_62CLIENT_IPPORT joined.
$_62CLIENT_IPPORT Test
$_63CLIENT_IPPORT joined.
$_63CLIENT_IPPORT Test
$_64CLIENT_IPPORT joined.
$_64CLIENT_IPPORT Test
$_65CLIENT_IPPORT joined.
$_65CLIENT_IPPORT Test
$_66CLIENT_IPPORT joined.
$_66CLIENT_IPPORT Test
$_67CLIENT_IPPORT joined.
$_67CLIENT_IPPORT Test
$_68CLIENT_IPPORT joined.
$_68CLIENT_IPPORT Test
$_69CLIENT_IPPORT joined.
$_69CLIENT_IPPORT Test
$_70CLIENT_IPPORT joined.
$_70CLIENT_IPPORT Test
$_71CLIENT_IPPORT joined.
$_71CLIENT_IPPORT Test
$_72CLIENT_IPPORT joined.
$_72CLIENT_IPPORT Test
$_73CLIENT_IPPORT joined.
$_73CLIENT_IPPORT Test
$_74CLIENT_IPPORT joined.
$_74CLIENT_IPPORT Test
$_75CLIENT_IPPORT joined.
$_75CLIENT_IPPORT Test
$_76CLIENT_IPPORT joined.
$_76CLIENT_IPPORT Test
$_77CLIENT_IPPORT joined.
$_77CLIENT_IPPORT Test
$_78CLIENT_IPPORT joined.
$_78CLIENT_IPPORT Test
$_79CLIENT_IPPORT joined.
$_79CLIENT_IPPORT Test
$_80CLIENT_IPPORT joined.
$_80CLIENT_IPPORT Test
$_81CLIENT_IPPORT joined.
$_81CLIENT_IPPORT Test
$_82CLIENT_IPPORT joined.
$_82CLIENT_IPPORT Test
$_83CLIENT_IPPORT joined.
$_83CLIENT_IPPORT Test
$_84CLIENT_IPPORT joined.
$_84CLIENT_IPPORT Test
$_85CLIENT_IPPORT joined.
$_85CLIENT_IPPORT Test
$_86CLIENT_IPPORT joined.
$_86CLIENT_IPPORT Test
$_87CLIENT_IPPORT joined.
$_87CLIENT_IPPORT Test
$_88CLIENT_IPPORT joined.
$_88CLIENT_IPPORT Test
$_89CLIENT_IPPORT joined.
$_89CLIENT_IPPORT Test
$_90CLIENT_IPPORT joined.
$_90CLIENT_IPPORT Test
$_91CLIENT_IPPORT joined.
$_91CLIENT_IPPORT Test
$_92CLIENT_IPPORT joined.
$_92CLIENT_IPPORT Test
$_93CLIENT_IPPORT joined.
$_93CLIENT_IPPORT Test
$_94CLIENT_IPPORT joined.
$_94CLIENT_IPPORT Test
$_95CLIENT_IPPORT joined.
$_95CLIENT_IPPORT Test
$_96CLIENT_IPPORT joined.
$_96CLIENT_IPPORT Test
$_97CLIENT_IPPORT joined.
$_97CLIENT_IPPORT Test
$_98CLIENT_IPPORT joined.
$_98CLIENT_IPPORT Test
$_99CLIENT_IPPORT joined.
$_99CLIENT_IPPORT Test
$_100CLIENT_IPPORT joined.
$_100CLIENT_IPPORT Test
$_101CLIENT_IPPORT joined.
$_101CLIENT_IPPORT Test
$_102CLIENT_IPPORT joined.
$_102CLIENT_IPPORT Test
$_103CLIENT_IPPORT joined.
$_103CLIENT_IPPORT Test
$_104CLIENT_IPPORT joined.
$_104CLIENT_IPPORT Test
$_105CLIENT_IPPORT joined.
$_105CLIENT_IPPORT Test
$_106CLIENT_IPPORT joined.
$_106CLIENT_IPPORT Test
$_107CLIENT_IPPORT joined.
$_107CLIENT_IPPORT Test
$_108CLIENT_IPPORT joined.
$_108CLIENT_IPPORT Test
$_109CLIENT_IPPORT joined.
$_109CLIENT_IPPORT Test
$_110CLIENT_IPPORT joined.
$_110CLIENT_IPPORT Test
$_111CLIENT_IPPORT joined.
$_111CLIENT_IPPORT Test
$_112CLIENT_IPPORT joined.
$_112CLIENT_IPPORT Test
$_113CLIENT_IPPORT joined.
$_113CLIENT_IPPORT Test
$_114CLIENT_IPPORT joined.
$_114CLIENT_IPPORT Test
$_115CLIENT_IPPORT joined.
$_115CLIENT_IPPORT Test
$_116CLIENT_IPPORT joined.
$_116CLIENT_IPPORT Test
$_117CLIENT_IPPORT joined.
$_117CLIENT_IPPORT Test
$_118CLIENT_IPPORT joined.
$_118CLIENT_IPPORT Test
$_119CLIENT_IPPORT joined.
$_119CLIENT_IPPORT Test
$_120CLIENT_IPPORT joined.
$_120CLIENT_IPPORT Test
$_121CLIENT_IPPORT joined.
$_121CLIENT_IPPORT Test
$_122CLIENT_IPPORT joined.
$_122CLIENT_IPPORT Test
$_123CLIENT_IPPORT joined.
$_123CLIENT_IPPORT Test
$_124CLIENT_IPPORT joined.
$_124CLIENT_IPPORT Test
$_125CLIENT_IPPORT joined.
$_125CLIENT_IPPORT Test
$_126CLIENT_IPPORT joined.
$_126CLIENT_IPPORT Test
$_127CLIENT_IPPORT joined.
$_127CLIENT_IPPORT Test
$_128CLIENT_IPPORT joined.
$_128CLIENT_IPPORT Test
$_129CLIENT_IPPORT joined.
$_129CLIENT_IPPORT Test
$_130CLIENT_IPPORT joined.
$_130CLIENT_IPPORT Test
$_131CLIENT_IPPORT joined.
$_131CLIENT_IPPORT Test
$_132CLIENT_IPPORT joined.
$_132CLIENT_IPPORT Test
$_133CLIENT_IPPORT joined.
$_133CLIENT_IPPORT Test
$_134CLIENT_IPPORT joined.
$_134CLIENT_IPPORT Test
$_135CLIENT_IPPORT joined.
$_135CLIENT_IPPORT Test
$_136CLIENT_IPPORT joined.
$_136CLIENT_IPPORT Test
$_137CLIENT_IPPORT joined.
$_137CLIENT_IPPORT Test
$_138CLIENT_IPPORT joined.
$_138CLIENT_IPPORT Test
$_139CLIENT_IPPORT joined.
$_139CLIENT_IPPORT Test
$_140CLIENT_IPPORT joined.
$_140CLIENT_IPPORT Test
$_141CLIENT_IPPORT joined.
$_141CLIENT_IPPORT Test
$_142CLIENT_IPPORT joined.
$_142CLIENT_IPPORT Test
$_143CLIENT_IPPORT joined.
$_143CLIENT_IPPORT Test
$_144CLIENT_IPPORT joined.
$_144CLIENT_IPPORT Test
$_145CLIENT_IPPORT joined.
$_145CLIENT_IPPORT Test
$_146CLIENT_IPPORT joined.
$_146CLIENT_IPPORT Test
$_147CLIENT_IPPORT joined.
$_147CLIENT_IPPORT Test
$_148CLIENT_IPPORT joined.
$_148CLIENT_IPPORT Test
$_149CLIENT_IPPORT joined.
$_149CLIENT_IPPORT Test
$_150CLIENT_IPPORT joined.
$_150CLIENT_IPPORT Test
$_151CLIENT_IPPORT joined.
$_151CLIENT_IPPORT Test
$_152CLIENT_IPPORT joined.
$_152CLIENT_IPPORT Test
$_153CLIENT_IPPORT joined.
$_153CLIENT_IPPORT Test
$_154CLIENT_IPPORT joined.
$_154CLIENT_IPPORT Test
$_155CLIENT_IPPORT joined.
$_155CLIENT_IPPORT Test
$_156CLIENT_IPPORT joined.
$_156CLIENT_IPPORT Test
$_157CLIENT_IPPORT joined.
$_157CLIENT_IPPORT Test
$_158CLIENT_IPPORT joined.
$_158CLIENT_IPPORT Test
$_159CLIENT_IPPORT joined.
$_159CLIENT_IPPORT Test
$_160CLIENT_IPPORT joined.
$_160CLIENT_IPPORT Test
$_161CLIENT_IPPORT joined.
$_161CLIENT_IPPORT Test
$_162CLIENT_IPPORT joined.
$_162CLIENT_IPPORT Test
$_163CLIENT_IPPORT joined.
$_163CLIENT_IPPORT Test
$_164CLIENT_IPPORT joined.
$_164CLIENT_IPPORT Test
$_165CLIENT_IPPORT joined.
$_165CLIENT_IPPORT Test
$_166CLIENT_IPPORT joined.
$_166CLIENT_IPPORT Test
$_167CLIENT_IPPORT joined.
$_167CLIENT_IPPORT Test
$_168CLIENT_IPPORT joined.
$_168CLIENT_IPPORT Test
$_169CLIENT_IPPORT joined.
$_169CLIENT_IPPORT Test
$_170CLIENT_IPPORT joined.
$_170CLIENT_IPPORT Test
$_171CLIENT_IPPORT joined.
$_171CLIENT_IPPORT Test
$_172CLIENT_IPPORT joined.
$_172CLIENT_IPPORT Test
$_173CLIENT_IPPORT joined.
$_173CLIENT_IPPORT Test
$_174CLIENT_IPPORT joined.
$_174CLIENT_IPPORT Test
$_175CLIENT_IPPORT joined.
$_175CLIENT_IPPORT Test
$_176CLIENT_IPPORT joined.
$_176CLIENT_IPPORT Test
$_177CLIENT_IPPORT joined.
$_177CLIENT_IPPORT Test
$_178CLIENT_IPPORT joined.
$_178CLIENT_IPPORT Test
$_179CLIENT_IPPORT joined.
$_179CLIENT_IPPORT Test
$_180CLIENT_IPPORT joined.
$_180CLIENT_IPPORT Test
$_181CLIENT_IPPORT joined.
$_181CLIENT_IPPORT Test
$_182CLIENT_IPPORT joined.
$_182CLIENT_IPPORT Test
$_183CLIENT_IPPORT joined.
$_183CLIENT_IPPORT Test
$_184CLIENT_IPPORT joined.
$_184CLIENT_IPPORT Test
$_185CLIENT_IPPORT joined.
$_185CLIENT_IPPORT Test
$_186CLIENT_IPPORT joined.
$_186CLIENT_IPPORT Test
$_187CLIENT_IPPORT joined.
$_187CLIENT_IPPORT Test
$_188CLIENT_IPPORT joined.
$_188CLIENT_IPPORT Test
$_189CLIENT_IPPORT joined.
$_189CLIENT_IPPORT Test
$_190CLIENT_IPPORT joined.
$_190CLIENT_IPPORT Test
$_191CLIENT_IPPORT joined.
$_191CLIENT_IPPORT Test
$_192CLIENT_IPPORT joined.
$_192CLIENT_IPPORT Test
$_193CLIENT_IPPORT joined.
$_193CLIENT_IPPORT Test
$_194CLIENT_IPPORT joined.
$_194CLIENT_IPPORT Test
$_195CLIENT_IPPORT joined.
$_195CLIENT_IPPORT Test
$_196CLIENT_IPPORT joined.
$_196CLIENT_IPPORT Test
$_197CLIENT_IPPORT joined.
$_197CLIENT_IPPORT Test
$_198CLIENT_IPPORT joined.
$_198CLIENT_IPPORT Test
$_199CLIENT_IPPORT joined.
$_199CLIENT_IPPORT Test
$_200CLIENT_IPPORT joined.
$_200CLIENT_IPPORT Test
$_201CLIENT_IPPORT joined.
$_201CLIENT_IPPORT Test
$_202CLIENT_IPPORT joined.
$_202CLIENT_IPPORT Test
$_203CLIENT_IPPORT joined.
$_203CLIENT_IPPORT Test
$_204CLIENT_IPPORT joined.
$_204CLIENT_IPPORT Test
$_205CLIENT_IPPORT joined.
$_205CLIENT_IPPORT Test
$_206CLIENT_IPPORT joined.
$_206CLIENT_IPPORT Test
$_207CLIENT_IPPORT joined.
$_207CLIENT_IPPORT Test
$_208CLIENT_IPPORT joined.
$_208CLIENT_IPPORT Test
$_209CLIENT_IPPORT joined.
$_209CLIENT_IPPORT Test
$_210CLIENT_IPPORT joined.
$_210CLIENT_IPPORT Test
$_211CLIENT_IPPORT joined.
$_211CLIENT_IPPORT Test
$_212CLIENT_IPPORT joined.
$_212CLIENT_IPPORT Test
$_213CLIENT_IPPORT joined.
$_213CLIENT_IPPORT Test
$_214CLIENT_IPPORT joined.
$_214CLIENT_IPPORT Test
$_215CLIENT_IPPORT joined.
$_215CLIENT_IPPORT Test
$_216CLIENT_IPPORT joined.
$_216CLIENT_IPPORT Test
$_217CLIENT_IPPORT joined.
$_217CLIENT_IPPORT Test
$_218CLIENT_IPPORT joined.
$_218CLIENT_IPPORT Test
$_219CLIENT_IPPORT joined.
$_219CLIENT_IPPORT Test
$_220CLIENT_IPPORT joined.
$_220CLIENT_IPPORT Test
$_221CLIENT_IPPORT joined.
$_221CLIENT_IPPORT Test
$_222CLIENT_IPPORT joined.
$_222CLIENT_IPPORT Test
$_223CLIENT_IPPORT joined.
$_223CLIENT_IPPORT Test
$_224CLIENT_IPPORT joined.
$_224CLIENT_IPPORT Test
$_225CLIENT_IPPORT joined.
$_225CLIENT_IPPORT Test
$_226CLIENT_IPPORT joined.
$_226CLIENT_IPPORT Test
$_227CLIENT_IPPORT joined.
$_227CLIENT_IPPORT Test
$_228CLIENT_IPPORT joined.
$_228CLIENT_IPPORT Test
$_229CLIENT_IPPORT joined.
$_229CLIENT_IPPORT Test
$_230CLIENT_IPPORT joined.
$_230CLIENT_IPPORT Test
$_231CLIENT_IPPORT joined.
$_231CLIENT_IPPORT Test
$_232CLIENT_IPPORT joined.
$_232CLIENT_IPPORT Test
$_233CLIENT_IPPORT joined.
$_233CLIENT_IPPORT Test
$_234CLIENT_IPPORT joined.
$_234CLIENT_IPPORT Test
$_235CLIENT_IPPORT joined.
$_235CLIENT_IPPORT Test
$_236CLIENT_IPPORT joined.
$_236CLIENT_IPPORT Test
$_237CLIENT_IPPORT joined.
$_237CLIENT_IPPORT Test
$_238CLIENT_IPPORT joined.
$_238CLIENT_IPPORT Test
$_239CLIENT_IPPORT joined.
$_239CLIENT_IPPORT Test
$_240CLIENT_IPPORT joined.
$_240CLIENT_IPPORT Test
$_241CLIENT_IPPORT joined.
$_241CLIENT_IPPORT Test
$_242CLIENT_IPPORT joined.
$_242CLIENT_IPPORT Test
$_243CLIENT_IPPORT joined.
$_243CLIENT_IPPORT Test
$_244CLIENT_IPPORT joined.
$_244CLIENT_IPPORT Test
$_245CLIENT_IPPORT joined.
$_245CLIENT_IPPORT Test
$_246CLIENT_IPPORT joined.
$_246CLIENT_IPPORT Test
$_247CLIENT_IPPORT joined.
$_247CLIENT_IPPORT Test
$_248CLIENT_IPPORT joined.
$_248CLIENT_IPPORT Test
$_249CLIENT_IPPORT joined.
$_249CLIENT_IPPORT Test
$_250CLIENT_IPPORT joined.
$_250CLIENT_IPPORT Test
$_251CLIENT_IPPORT joined.
$_251CLIENT_IPPORT Test
$_252CLIENT_IPPORT joined.
$_252CLIENT_IPPORT Test
$_253CLIENT_IPPORT joined.
$_253CLIENT_IPPORT Test
$_254CLIENT_IPPORT joined.
$_254CLIENT_IPPORT Test
$_255CLIENT_IPPORT joined.
$_255CLIENT_IPPORT Test
$_256CLIENT_IPPORT joined.
$_256CLIENT_IPPORT Test
$_257CLIENT_IPPORT joined.
$_257CLIENT_IPPORT Test
$_258CLIENT_IPPORT joined.
$_258CLIENT_IPPORT Test
$_259CLIENT_IPPORT joined.
$_259CLIENT_IPPORT Test
$_260CLIENT_IPPORT joined.
$_260CLIENT_IPPORT Test
$_261CLIENT_IPPORT joined.
$_261CLIENT_IPPORT Test
$_262CLIENT_IPPORT joined.
$_262CLIENT_IPPORT Test
$_263CLIENT_IPPORT joined.
$_263CLIENT_IPPORT Test
$_264CLIENT_IPPORT joined.
$_264CLIENT_IPPORT Test
$_265CLIENT_IPPORT joined.
$_265CLIENT_IPPORT Test
$_266CLIENT_IPPORT joined.
$_266CLIENT_IPPORT Test
$_267CLIENT_IPPORT joined.
$_267CLIENT_IPPORT Test
$_268CLIENT_IPPORT joined.
$_268CLIENT_IPPORT Test
$_269CLIENT_IPPORT joined.
$_269CLIENT_IPPORT Test
$_270CLIENT_IPPORT joined.
$_270CLIENT_IPPORT Test
$_271CLIENT_IPPORT joined.
$_271CLIENT_IPPORT Test
$_272CLIENT_IPPORT joined.
$_272CLIENT_IPPORT Test
$_273CLIENT_IPPORT joined.
$_273CLIENT_IPPORT Test
$_274CLIENT_IPPORT joined.
$_274CLIENT_IPPORT Test
$_275CLIENT_IPPORT joined.
$_275CLIENT_IPPORT Test
$_276CLIENT_IPPORT joined.
$_276CLIENT_IPPORT Test
$_277CLIENT_IPPORT joined.
$_277CLIENT_IPPORT Test
$_278CLIENT_IPPORT joined.
$_278CLIENT_IPPORT Test
$_279CLIENT_IPPORT joined.
$_279CLIENT_IPPORT Test
$_280CLIENT_IPPORT joined.
$_280CLIENT_IPPORT Test
$_281CLIENT_IPPORT joined.
$_281CLIENT_IPPORT Test
$_282CLIENT_IPPORT joined.
$_282CLIENT_IPPORT Test
$_283CLIENT_IPPORT joined.
$_283CLIENT_IPPORT Test
$_284CLIENT_IPPORT joined.
$_284CLIENT_IPPORT Test
$_285CLIENT_IPPORT joined.
$_285CLIENT_IPPORT Test
$_286CLIENT_IPPORT joined.
$_286CLIENT_IPPORT Test
$_287CLIENT_IPPORT joined.
$_287CLIENT_IPPORT Test
$_288CLIENT_IPPORT joined.
$_288CLIENT_IPPORT Test
$_289CLIENT_IPPORT joined.
$_289CLIENT_IPPORT Test
$_290CLIENT_IPPORT joined.
$_290CLIENT_IPPORT Test
$_291CLIENT_IPPORT joined.
$_291CLIENT_IPPORT Test
$_292CLIENT_IPPORT joined.
$_292CLIENT_IPPORT Test
$_293CLIENT_IPPORT joined.
$_293CLIENT_IPPORT Test
$_294CLIENT_IPPORT joined.
$_294CLIENT_IPPORT Test
$_295CLIENT_IPPORT joined.
$_295CLIENT_IPPORT Test
$_296CLIENT_IPPORT joined.
$_296CLIENT_IPPORT Test
$_297CLIENT_IPPORT joined.
$_297CLIENT_IPPORT Test
$_298CLIENT_IPPORT joined.
$_298CLIENT_IPPORT Test
$_299CLIENT_IPPORT joined.
$_299CLIENT_IPPORT Test
$_300CLIENT_IPPORT joined.
$_300CLIENT_IPPORT Test
$_301CLIENT_IPPORT joined.
$_301CLIENT_IPPORT Test
$_302CLIENT_IPPORT joined.
$_302CLIENT_IPPORT Test
$_303CLIENT_IPPORT joined.
$_303CLIENT_IPPORT Test
$_304CLIENT_IPPORT joined.
$_304CLIENT_IPPORT Test
$_305CLIENT_IPPORT joined.
$_305CLIENT_IPPORT Test
$_306CLIENT_IPPORT joined.
$_306CLIENT_IPPORT Test
$_307CLIENT_IPPORT joined.
$_307CLIENT_IPPORT Test
$_308CLIENT_IPPORT joined.
$_308CLIENT_IPPORT Test
$_309CLIENT_IPPORT joined.
$_309CLIENT_IPPORT Test
$_310CLIENT_IPPORT joined.
$_310CLIENT_IPPORT Test
$_311CLIENT_IPPORT joined.
$_311CLIENT_IPPORT Test
$_312CLIENT_IPPORT joined.
$_312CLIENT_IPPORT Test
$_313CLIENT_IPPORT joined.
$_313CLIENT_IPPORT Test
$_314CLIENT_IPPORT joined.
$_314CLIENT_IPPORT Test
$_315CLIENT_IPPORT joined.
$_315CLIENT_IPPORT Test
$_316CLIENT_IPPORT joined.
$_316CLIENT_IPPORT Test
$_317CLIENT_IPPORT joined.
$_317CLIENT_IPPORT Test
$_318CLIENT_IPPORT joined.
$_318CLIENT_IPPORT Test
$_319CLIENT_IPPORT joined.
$_319CLIENT_IPPORT Test
$_320CLIENT_IPPORT joined.
$_320CLIENT_IPPORT Test
$_321CLIENT_IPPORT joined.
$_321CLIENT_IPPORT Test
$_322CLIENT_IPPORT joined.
$_322CLIENT_IPPORT Test
$_323CLIENT_IPPORT joined.
$_323CLIENT_IPPORT Test
$_324CLIENT_IPPORT joined.
$_324CLIENT_IPPORT Test
$_325CLIENT_IPPORT joined.
$_325CLIENT_IPPORT Test
$_326CLIENT_IPPORT joined.
$_326CLIENT_IPPORT Test
$_327CLIENT_IPPORT joined.
$_327CLIENT_IPPORT Test
$_328CLIENT_IPPORT joined.
$_328CLIENT_IPPORT Test
$_329CLIENT_IPPORT joined.
$_329CLIENT_IPPORT Test
$_330CLIENT_IPPORT joined.
$_330CLIENT_IPPORT Test
$_331CLIENT_IPPORT joined.
$_331CLIENT_IPPORT Test
$_332CLIENT_IPPORT joined.
$_332CLIENT_IPPORT Test
$_333CLIENT_IPPORT joined.
$_333CLIENT_IPPORT Test
$_334CLIENT_IPPORT joined.
$_334CLIENT_IPPORT Test
$_335CLIENT_IPPORT joined.
$_335CLIENT_IPPORT Test
$_336CLIENT_IPPORT joined.
$_336CLIENT_IPPORT Test
$_337CLIENT_IPPORT joined.
$_337CLIENT_IPPORT Test
$_338CLIENT_IPPORT joined.
$_338CLIENT_IPPORT Test
$_339CLIENT_IPPORT joined.
$_339CLIENT_IPPORT Test
$_340CLIENT_IPPORT joined.
$_340CLIENT_IPPORT Test
$_341CLIENT_IPPORT joined.
$_341CLIENT_IPPORT Test
$_342CLIENT_IPPORT joined.
$_342CLIENT_IPPORT Test
$_343CLIENT_IPPORT joined.
$_343CLIENT_IPPORT Test
$_344CLIENT_IPPORT joined.
$_344CLIENT_IPPORT Test
$_345CLIENT_IPPORT joined.
$_345CLIENT_IPPORT Test
$_346CLIENT_IPPORT joined.
$_346CLIENT_IPPORT Test
$_347CLIENT_IPPORT joined.
$_347CLIENT_IPPORT Test
$_348CLIENT_IPPORT joined.
$_348CLIENT_IPPORT Test
$_349CLIENT_IPPORT joined.
$_349CLIENT_IPPORT Test
$_350CLIENT_IPPORT joined.
$_350CLIENT_IPPORT Test
$_351CLIENT_IPPORT joined.
$_351CLIENT_IPPORT Test
$_352CLIENT_IPPORT joined.
$_352CLIENT_IPPORT Test
$_353CLIENT_IPPORT joined.
$_353CLIENT_IPPORT Test
$_354CLIENT_IPPORT joined.
$_354CLIENT_IPPORT Test
$_355CLIENT_IPPORT joined.
$_355CLIENT_IPPORT Test
$_356CLIENT_IPPORT joined.
$_356CLIENT_IPPORT Test
$_357CLIENT_IPPORT joined.
$_357CLIENT_IPPORT Test
$_358CLIENT_IPPORT joined.
$_358CLIENT_IPPORT Test
$_359CLIENT_IPPORT joined.
$_359CLIENT_IPPORT Test
$_360CLIENT_IPPORT joined.
$_360CLIENT_IPPORT Test
$_361CLIENT_IPPORT joined.
$_361CLIENT_IPPORT Test
$_362CLIENT_IPPORT joined.
$_362CLIENT_IPPORT Test
$_363CLIENT_IPPORT joined.
$_363CLIENT_IPPORT Test
$_364CLIENT_IPPORT joined.
$_364CLIENT_IPPORT Test
$_365CLIENT_IPPORT joined.
$_365CLIENT_IPPORT Test
$_366CLIENT_IPPORT joined.
$_366CLIENT_IPPORT Test
$_367CLIENT_IPPORT joined.
$_367CLIENT_IPPORT Test
$_368CLIENT_IPPORT joined.
$_368CLIENT_IPPORT Test
$_369CLIENT_IPPORT joined.
$_369CLIENT_IPPORT Test
$_370CLIENT_IPPORT joined.
$_370CLIENT_IPPORT Test
$_371CLIENT_IPPORT joined.
$_371CLIENT_IPPORT Test
$_372CLIENT_IPPORT joined.
$_372CLIENT_IPPORT Test
$_373CLIENT_IPPORT joined.
$_373CLIENT_IPPORT Test
$_374CLIENT_IPPORT joined.
$_374CLIENT_IPPORT Test
$_375CLIENT_IPPORT joined.
$_375CLIENT_IPPORT Test
$_376CLIENT_IPPORT joined.
$_376CLIENT_IPPORT Test
$_377CLIENT_IPPORT joined.
$_377CLIENT_IPPORT Test
$_378CLIENT_IPPORT joined.
$_378CLIENT_IPPORT Test
$_379CLIENT_IPPORT joined.
$_379CLIENT_IPPORT Test
$_380CLIENT_IPPORT joined.
$_380CLIENT_IPPORT Test
$_381CLIENT_IPPORT joined.
$_381CLIENT_IPPORT Test
$_382CLIENT_IPPORT joined.
$_382CLIENT_IPPORT Test
$_383CLIENT_IPPORT joined.
$_383CLIENT_IPPORT Test
$_384CLIENT_IPPORT joined.
$_384CLIENT_IPPORT Test
$_385CLIENT_IPPORT joined.
$_385CLIENT_IPPORT Test
$_386CLIENT_IPPORT joined.
$_386CLIENT_IPPORT Test
$_387CLIENT_IPPORT joined.
$_387CLIENT_IPPORT Test
$_388CLIENT_IPPORT joined.
$_388CLIENT_IPPORT Test
$_389CLIENT_IPPORT joined.
$_389CLIENT_IPPORT Test
$_390CLIENT_IPPORT joined.
$_390CLIENT_IPPORT Test
$_391CLIENT_IPPORT joined.
$_391CLIENT_IPPORT Test
$_392CLIENT_IPPORT joined.
$_392CLIENT_IPPORT Test
$_393CLIENT_IPPORT joined.
$_393CLIENT_IPPORT Test
$_394CLIENT_IPPORT joined.
$_394CLIENT_IPPORT Test
$_395CLIENT_IPPORT joined.
$_395CLIENT_IPPORT Test
$_396CLIENT_IPPORT joined.
$_396CLIENT_IPPORT Test
$_397CLIENT_IPPORT joined.
$_397CLIENT_IPPORT Test
$_398CLIENT_IPPORT joined.
$_398CLIENT_IPPORT Test
$_399CLIENT_IPPORT joined.
$_399CLIENT_IPPORT Test
$_400CLIENT_IPPORT joined.
$_400CLIENT_IPPORT Test
$_401CLIENT_IPPORT joined.
$_401CLIENT_IPPORT Test
$_402CLIENT_IPPORT joined.
$_402CLIENT_IPPORT Test
$_403CLIENT_IPPORT joined.
$_403CLIENT_IPPORT Test
$_404CLIENT_IPPORT joined.
$_404CLIENT_IPPORT Test
$_405CLIENT_IPPORT joined.
$_405CLIENT_IPPORT Test
$_406CLIENT_IPPORT joined.
$_406CLIENT_IPPORT Test
$_407CLIENT_IPPORT joined.
$_407CLIENT_IPPORT Test
$_408CLIENT_IPPORT joined.
$_408CLIENT_IPPORT Test
$_409CLIENT_IPPORT joined.
$_409CLIENT_IPPORT Test
$_410CLIENT_IPPORT joined.
$_410CLIENT_IPPORT Test
$_411CLIENT_IPPORT joined.
$_411CLIENT_IPPORT Test
$_412CLIENT_IPPORT joined.
$_412CLIENT_IPPORT Test
$_413CLIENT_IPPORT joined.
$_413CLIENT_IPPORT Test
$_414CLIENT_IPPORT joined.
$_414CLIENT_IPPORT Test
$_415CLIENT_IPPORT joined.
$_415CLIENT_IPPORT Test
$_416CLIENT_IPPORT joined.
$_416CLIENT_IPPORT Test
$_417CLIENT_IPPORT joined.
$_417CLIENT_IPPORT Test
$_418CLIENT_IPPORT joined.
$_418CLIENT_IPPORT Test
$_419CLIENT_IPPORT joined.
$_419CLIENT_IPPORT Test
$_420CLIENT_IPPORT joined.
$_420CLIENT_IPPORT Test
$_421CLIENT_IPPORT joined.
$_421CLIENT_IPPORT Test
$_422CLIENT_IPPORT joined.
$_422CLIENT_IPPORT Test
$_423CLIENT_IPPORT joined.
$_423CLIENT_IPPORT Test
$_424CLIENT_IPPORT joined.
$_424CLIENT_IPPORT Test
$_425CLIENT_IPPORT joined.
$_425CLIENT_IPPORT Test
$_426CLIENT_IPPORT joined.
$_426CLIENT_IPPORT Test
$_427CLIENT_IPPORT joined.
$_427CLIENT_IPPORT Test
$_428CLIENT_IPPORT joined.
$_428CLIENT_IPPORT Test
$_429CLIENT_IPPORT joined.
$_429CLIENT_IPPORT Test
$_430CLIENT_IPPORT joined.
$_430CLIENT_IPPORT Test
$_431CLIENT_IPPORT joined.
$_431CLIENT_IPPORT Test
$_432CLIENT_IPPORT joined.
$_432CLIENT_IPPORT Test
$_433CLIENT_IPPORT joined.
$_433CLIENT_IPPORT Test
$_434CLIENT_IPPORT joined.
$_434CLIENT_IPPORT Test
$_435CLIENT_IPPORT joined.
$_435CLIENT_IPPORT Test
$_436CLIENT_IPPORT joined.
$_436CLIENT_IPPORT Test
$_437CLIENT_IPPORT joined.
$_437CLIENT_IPPORT Test
$_438CLIENT_IPPORT joined.
$_438CLIENT_IPPORT Test
$_439CLIENT_IPPORT joined.
$_439CLIENT_IPPORT Test
$_440CLIENT_IPPORT joined.
$_440CLIENT_IPPORT Test
$_441CLIENT_IPPORT joined.
$_441CLIENT_IPPORT Test
$_442CLIENT_IPPORT joined.
$_442CLIENT_IPPORT Test
$_443CLIENT_IPPORT joined.
$_443CLIENT_IPPORT Test
$_444CLIENT_IPPORT joined.
$_444CLIENT_IPPORT Test
$_445CLIENT_IPPORT joined.
$_445CLIENT_IPPORT Test
$_446CLIENT_IPPORT joined.
$_446CLIENT_IPPORT Test
$_447CLIENT_IPPORT joined.
$_447CLIENT_IPPORT Test
$_448CLIENT_IPPORT joined.
$_448CLIENT_IPPORT Test
$_449CLIENT_IPPORT joined.
$_449CLIENT_IPPORT Test
$_450CLIENT_IPPORT joined.
$_450CLIENT_IPPORT Test
$_451CLIENT_IPPORT joined.
$_451CLIENT_IPPORT Test
$_452CLIENT_IPPORT joined.
$_452CLIENT_IPPORT Test
$_453CLIENT_IPPORT joined.
$_453CLIENT_IPPORT Test
$_454CLIENT_IPPORT joined.
$_454CLIENT_IPPORT Test
$_455CLIENT_IPPORT joined.
$_455CLIENT_IPPORT Test
$_456CLIENT_IPPORT joined.
$_456CLIENT_IPPORT Test
$_457CLIENT_IPPORT joined.
$_457CLIENT_IPPORT Test
$_458CLIENT_IPPORT joined.
$_458CLIENT_IPPORT Test
$_459CLIENT_IPPORT joined.
$_459CLIENT_IPPORT Test
$_460CLIENT_IPPORT joined.
$_460CLIENT_IPPORT Test
$_461CLIENT_IPPORT joined.
$_461CLIENT_IPPORT Test
$_462CLIENT_IPPORT joined.
$_462CLIENT_IPPORT Test
$_463CLIENT_IPPORT joined.
$_463CLIENT_IPPORT Test
$_464CLIENT_IPPORT joined.
$_464CLIENT_IPPORT Test
$_465CLIENT_IPPORT joined.
$_465CLIENT_IPPORT Test
$_466CLIENT_IPPORT joined.
$_466CLIENT_IPPORT Test
$_467CLIENT_IPPORT joined.
$_467CLIENT_IPPORT Test
$_468CLIENT_IPPORT joined.
$_468CLIENT_IPPORT Test
$_469CLIENT_IPPORT joined.
$_469CLIENT_IPPORT Test
$_470CLIENT_IPPORT joined.
$_470CLIENT_IPPORT Test
$_471CLIENT_IPPORT joined.
$_471CLIENT_IPPORT Test
$_472CLIENT_IPPORT joined.
$_472CLIENT_IPPORT Test
$_473CLIENT_IPPORT joined.
$_473CLIENT_IPPORT Test
$_474CLIENT_IPPORT joined.
$_474CLIENT_IPPORT Test
$_475CLIENT_IPPORT joined.
$_475CLIENT_IPPORT Test
$_476CLIENT_IPPORT joined.
$_476CLIENT_IPPORT Test
$_477CLIENT_IPPORT joined.
$_477CLIENT_IPPORT Test
$_478CLIENT_IPPORT joined.
$_478CLIENT_IPPORT Test
$_479CLIENT_IPPORT joined.
$_479CLIENT_IPPORT Test
$_480CLIENT_IPPORT joined.
$_480CLIENT_IPPORT Test
$_481CLIENT_IPPORT joined.
$_481CLIENT_IPPORT Test
$_482CLIENT_IPPORT joined.
$_482CLIENT_IPPORT Test
$_483CLIENT_IPPORT joined.
$_483CLIENT_IPPORT Test
$_484CLIENT_IPPORT joined.
$_484CLIENT_IPPORT Test
$_485CLIENT_IPPORT joined.
$_485CLIENT_IPPORT Test
$_486CLIENT_IPPORT joined.
$_486CLIENT_IPPORT Test
$_487CLIENT_IPPORT joined.
$_487CLIENT_IPPORT Test
$_488CLIENT_IPPORT joined.
$_488CLIENT_IPPORT Test
$_489CLIENT_IPPORT joined.
$_489CLIENT_IPPORT Test
$_490CLIENT_IPPORT joined.
$_490CLIENT_IPPORT Test
$_491CLIENT_IPPORT joined.
$_491CLIENT_IPPORT Test
$_492CLIENT_IPPORT joined.
$_492CLIENT_IPPORT Test
$_493CLIENT_IPPORT joined.
$_493CLIENT_IPPORT Test
$_494CLIENT_IPPORT joined.
$_494CLIENT_IPPORT Test
$_495CLIENT_IPPORT joined.
$_495CLIENT_IPPORT Test
$_496CLIENT_IPPORT joined.
$_496CLIENT_IPPORT Test
$_497CLIENT_IPPORT joined.
$_497CLIENT_IPPORT Test
$_498CLIENT_IPPORT joined.
$_498CLIENT_IPPORT Test
$_499CLIENT_IPPORT joined.
$_499CLIENT_IPPORT Test
$_500CLIENT_IPPORT joined.
$_500CLIENT_IPPORT Test
$_501CLIENT_IPPORT joined.
$_501CLIENT_IPPORT Test
$_502CLIENT_IPPORT joined.
$_502CLIENT_IPPORT Test
$_503CLIENT_IPPORT joined.
$_503CLIENT_IPPORT Test
$_504CLIENT_IPPORT joined.
$_504CLIENT_IPPORT Test
$_505CLIENT_IPPORT joined.
$_505CLIENT_IPPORT Test
$_506CLIENT_IPPORT joined.
$_506CLIENT_IPPORT Test
$_507CLIENT_IPPORT joined.
$_507CLIENT_IPPORT Test
$_508CLIENT_IPPORT joined.
$_508CLIENT_IPPORT Test
$_509CLIENT_IPPORT joined.
$_509CLIENT_IPPORT Test
$_510CLIENT_IPPORT joined.
$_510CLIENT_IPPORT Test
$_511CLIENT_IPPORT joined.
$_511CLIENT_IPPORT Test
$_512CLIENT_IPPORT joined.
$_512CLIENT_IPPORT Test
$_513CLIENT_IPPORT joined.
$_513CLIENT_IPPORT Test
$_514CLIENT_IPPORT joined.
$_514CLIENT_IPPORT Test
$_515CLIENT_IPPORT joined.
$_515CLIENT_IPPORT Test
$_516CLIENT_IPPORT joined.
$_516CLIENT_IPPORT Test
$_517CLIENT_IPPORT joined.
$_517CLIENT_IPPORT Test
$_518CLIENT_IPPORT joined.
$_518CLIENT_IPPORT Test
$_519CLIENT_IPPORT joined.
$_519CLIENT_IPPORT Test
$_520CLIENT_IPPORT joined.
$_520CLIENT_IPPORT Test
$_521CLIENT_IPPORT joined.
$_521CLIENT_IPPORT Test
$_522CLIENT_IPPORT joined.
$_522CLIENT_IPPORT Test
$_523CLIENT_IPPORT joined.
$_523CLIENT_IPPORT Test
$_524CLIENT_IPPORT joined.
$_524CLIENT_IPPORT Test
$_525CLIENT_IPPORT joined.
$_525CLIENT_IPPORT Test
$_526CLIENT_IPPORT joined.
$_526CLIENT_IPPORT Test
$_527CLIENT_IPPORT joined.
$_527CLIENT_IPPORT Test
$_528CLIENT_IPPORT joined.
$_528CLIENT_IPPORT Test
$_529CLIENT_IPPORT joined.
$_529CLIENT_IPPORT Test
$_530CLIENT_IPPORT joined.
$_530CLIENT_IPPORT Test
$_531CLIENT_IPPORT joined.
$_531CLIENT_IPPORT Test
$_532CLIENT_IPPORT joined.
$_532CLIENT_IPPORT Test
$_533CLIENT_IPPORT joined.
$_533CLIENT_IPPORT Test
$_534CLIENT_IPPORT joined.
$_534CLIENT_IPPORT Test
$_535CLIENT_IPPORT joined.
$_535CLIENT_IPPORT Test
$_536CLIENT_IPPORT joined.
$_536CLIENT_IPPORT Test
$_537CLIENT_IPPORT joined.
$_537CLIENT_IPPORT Test
$_538CLIENT_IPPORT joined.
$_538CLIENT_IPPORT Test
$_539CLIENT_IPPORT joined.
$_539CLIENT_IPPORT Test
$_540CLIENT_IPPORT joined.
$_540CLIENT_IPPORT Test
$_541CLIENT_IPPORT joined.
$_541CLIENT_IPPORT Test
$_542CLIENT_IPPORT joined.
$_542CLIENT_IPPORT Test
$_543CLIENT_IPPORT joined.
$_543CLIENT_IPPORT Test
$_544CLIENT_IPPORT joined.
$_544CLIENT_IPPORT Test
$_545CLIENT_IPPORT joined.
$_545CLIENT_IPPORT Test
$_546CLIENT_IPPORT joined.
$_546CLIENT_IPPORT Test
$_547CLIENT_IPPORT joined.
$_547CLIENT_IPPORT Test
$_548CLIENT_IPPORT joined.
$_548CLIENT_IPPORT Test
$_549CLIENT_IPPORT joined.
$_549CLIENT_IPPORT Test
$_550CLIENT_IPPORT joined.
$_550CLIENT_IPPORT Test
$_551CLIENT_IPPORT joined.
$_551CLIENT_IPPORT Test
$_552CLIENT_IPPORT joined.
$_552CLIENT_IPPORT Test
$_553CLIENT_IPPORT joined.
$_553CLIENT_IPPORT Test
$_554CLIENT_IPPORT joined.
$_554CLIENT_IPPORT Test
$_555CLIENT_IPPORT joined.
$_555CLIENT_IPPORT Test
$_556CLIENT_IPPORT joined.
$_556CLIENT_IPPORT Test
$_557CLIENT_IPPORT joined.
$_557CLIENT_IPPORT Test
$_558CLIENT_IPPORT joined.
$_558CLIENT_IPPORT Test
$_559CLIENT_IPPORT joined.
$_559CLIENT_IPPORT Test
$_560CLIENT_IPPORT joined.
$_560CLIENT_IPPORT Test
$_561CLIENT_IPPORT joined.
$_561CLIENT_IPPORT Test
$_562CLIENT_IPPORT joined.
$_562CLIENT_IPPORT Test
$_563CLIENT_IPPORT joined.
$_563CLIENT_IPPORT Test
$_564CLIENT_IPPORT joined.
$_564CLIENT_IPPORT Test
$_565CLIENT_IPPORT joined.
$_565CLIENT_IPPORT Test
$_566CLIENT_IPPORT joined.
$_566CLIENT_IPPORT Test
$_567CLIENT_IPPORT joined.
$_567CLIENT_IPPORT Test
$_568CLIENT_IPPORT joined.
$_568CLIENT_IPPORT Test
$_569CLIENT_IPPORT joined.
$_569CLIENT_IPPORT Test
$_570CLIENT_IPPORT joined.
$_570CLIENT_IPPORT Test
$_571CLIENT_IPPORT joined.
$_571CLIENT_IPPORT Test
$_572CLIENT_IPPORT joined.
$_572CLIENT_IPPORT Test
$_573CLIENT_IPPORT joined.
$_573CLIENT_IPPORT Test
$_574CLIENT_IPPORT joined.
$_574CLIENT_IPPORT Test
$_575CLIENT_IPPORT joined.
$_575CLIENT_IPPORT Test
$_576CLIENT_IPPORT joined.
$_576CLIENT_IPPORT Test
$_577CLIENT_IPPORT joined.
$_577CLIENT_IPPORT Test
$_578CLIENT_IPPORT joined.
$_578CLIENT_IPPORT Test
$_579CLIENT_IPPORT joined.
$_579CLIENT_IPPORT Test
$_580CLIENT_IPPORT joined.
$_580CLIENT_IPPORT Test
$_581CLIENT_IPPORT joined.
$_581CLIENT_IPPORT Test
$_582CLIENT_IPPORT joined.
$_582CLIENT_IPPORT Test
$_583CLIENT_IPPORT joined.
$_583CLIENT_IPPORT Test
$_584CLIENT_IPPORT joined.
$_584CLIENT_IPPORT Test
$_585CLIENT_IPPORT joined.
$_585CLIENT_IPPORT Test
$_586CLIENT_IPPORT joined.
$_586CLIENT_IPPORT Test
$_587CLIENT_IPPORT joined.
$_587CLIENT_IPPORT Test
$_588CLIENT_IPPORT joined.
$_588CLIENT_IPPORT Test
$_589CLIENT_IPPORT joined.
$_589CLIENT_IPPORT Test
$_590CLIENT_IPPORT joined.
$_590CLIENT_IPPORT Test
$_591CLIENT_IPPORT joined.
$_591CLIENT_IPPORT Test
$_592CLIENT_IPPORT joined.
$_592CLIENT_IPPORT Test
$_593CLIENT_IPPORT joined.
$_593CLIENT_IPPORT Test
$_594CLIENT_IPPORT joined.
$_594CLIENT_IPPORT Test
$_595CLIENT_IPPORT joined.
$_595CLIENT_IPPORT Test
$_596CLIENT_IPPORT joined.
$_596CLIENT_IPPORT Test
$_597CLIENT_IPPORT joined.
$_597CLIENT_IPPORT Test
$_598CLIENT_IPPORT joined.
$_598CLIENT_IPPORT Test
$_599CLIENT_IPPORT joined.
$_599CLIENT_IPPORT Test
$_600CLIENT_IPPORT joined.
$_600CLIENT_IPPORT Test
$_601CLIENT_IPPORT joined.
$_601CLIENT_IPPORT Test
$_602CLIENT_IPPORT joined.
$_602CLIENT_IPPORT Test
$_603CLIENT_IPPORT joined.
$_603CLIENT_IPPORT Test
$_604CLIENT_IPPORT joined.
$_604CLIENT_IPPORT Test
$_605CLIENT_IPPORT joined.
$_605CLIENT_IPPORT Test
$_606CLIENT_IPPORT joined.
$_606CLIENT_IPPORT Test
$_607CLIENT_IPPORT joined.
$_607CLIENT_IPPORT Test
$_608CLIENT_IPPORT joined.
$_608CLIENT_IPPORT Test
$_609CLIENT_IPPORT joined.
$_609CLIENT_IPPORT Test
$_610CLIENT_IPPORT joined.
$_610CLIENT_IPPORT Test
$_611CLIENT_IPPORT joined.
$_611CLIENT_IPPORT Test
$_612CLIENT_IPPORT joined.
$_612CLIENT_IPPORT Test
$_613CLIENT_IPPORT joined.
$_613CLIENT_IPPORT Test
$_614CLIENT_IPPORT joined.
$_614CLIENT_IPPORT Test
$_615CLIENT_IPPORT joined.
$_615CLIENT_IPPORT Test
$_616CLIENT_IPPORT joined.
$_616CLIENT_IPPORT Test
$_617CLIENT_IPPORT joined.
$_617CLIENT_IPPORT Test
$_618CLIENT_IPPORT joined.
$_618CLIENT_IPPORT Test
$_619CLIENT_IPPORT joined.
$_619CLIENT_IPPORT Test
$_620CLIENT_IPPORT joined.
$_620CLIENT_IPPORT Test
$_621CLIENT_IPPORT joined.
$_621CLIENT_IPPORT Test
$_622CLIENT_IPPORT joined.
$_622CLIENT_IPPORT Test
$_623CLIENT_IPPORT joined.
$_623CLIENT_IPPORT Test
$_624CLIENT_IPPORT joined.
$_624CLIENT_IPPORT Test
$_625CLIENT_IPPORT joined.
$_625CLIENT_IPPORT Test
$_626CLIENT_IPPORT joined.
$_626CLIENT_IPPORT Test
$_627CLIENT_IPPORT joined.
$_627CLIENT_IPPORT Test
$_628CLIENT_IPPORT joined.
$_628CLIENT_IPPORT Test
$_629CLIENT_IPPORT joined.
$_629CLIENT_IPPORT Test
$_630CLIENT_IPPORT joined.
$_630CLIENT_IPPORT Test
$_631CLIENT_IPPORT joined.
$_631CLIENT_IPPORT Test
$_632CLIENT_IPPORT joined.
$_632CLIENT_IPPORT Test
$_633CLIENT_IPPORT joined.
$_633CLIENT_IPPORT Test
$_634CLIENT_IPPORT joined.
$_634CLIENT_IPPORT Test
$_635CLIENT_IPPORT joined.
$_635CLIENT_IPPORT Test
$_636CLIENT_IPPORT joined.
$_636CLIENT_IPPORT Test
$_637CLIENT_IPPORT joined.
$_637CLIENT_IPPORT Test
$_638CLIENT_IPPORT joined.
$_638CLIENT_IPPORT Test
$_639CLIENT_IPPORT joined.
$_639CLIENT_IPPORT Test
$_640CLIENT_IPPORT joined.
$_640CLIENT_IPPORT Test
$_641CLIENT_IPPORT joined.
$_641CLIENT_IPPORT Test
$_642CLIENT_IPPORT joined.
$_642CLIENT_IPPORT Test
$_643CLIENT_IPPORT joined.
$_643CLIENT_IPPORT Test
$_644CLIENT_IPPORT joined.
$_644CLIENT_IPPORT Test
$_645CLIENT_IPPORT joined.
$_645CLIENT_IPPORT Test
$_646CLIENT_IPPORT joined.
$_646CLIENT_IPPORT Test
$_647CLIENT_IPPORT joined.
$_647CLIENT_IPPORT Test
$_648CLIENT_IPPORT joined.
$_648CLIENT_IPPORT Test
$_649CLIENT_IPPORT joined.
$_649CLIENT_IPPORT Test
$_650CLIENT_IPPORT joined.
$_650CLIENT_IPPORT Test
$_651CLIENT_IPPORT joined.
$_651CLIENT_IPPORT Test
$_652CLIENT_IPPORT joined.
$_652CLIENT_IPPORT Test
$_653CLIENT_IPPORT joined.
$_653CLIENT_IPPORT Test
$_654CLIENT_IPPORT joined.
$_654CLIENT_IPPORT Test
$_655CLIENT_IPPORT joined.
$_655CLIENT_IPPORT Test
$_656CLIENT_IPPORT joined.
$_656CLIENT_IPPORT Test
$_657CLIENT_IPPORT joined.
$_657CLIENT_IPPORT Test
$_658CLIENT_IPPORT joined.
$_658CLIENT_IPPORT Test
$_659CLIENT_IPPORT joined.
$_659CLIENT_IPPORT Test
$_660CLIENT_IPPORT joined.
$_660CLIENT_IPPORT Test
$_661CLIENT_IPPORT joined.
$_661CLIENT_IPPORT Test
$_662CLIENT_IPPORT joined.
$_662CLIENT_IPPORT Test
$_663CLIENT_IPPORT joined.
$_663CLIENT_IPPORT Test
$_664CLIENT_IPPORT joined.
$_664CLIENT_IPPORT Test
$_665CLIENT_IPPORT joined.
$_665CLIENT_IPPORT Test
$_666CLIENT_IPPORT joined.
$_666CLIENT_IPPORT Test
$_667CLIENT_IPPORT joined.
$_667CLIENT_IPPORT Test
$_668CLIENT_IPPORT joined.
$_668CLIENT_IPPORT Test
$_669CLIENT_IPPORT joined.
$_669CLIENT_IPPORT Test
$_670CLIENT_IPPORT joined.
$_670CLIENT_IPPORT Test
$_671CLIENT_IPPORT joined.
$_671CLIENT_IPPORT Test
$_672CLIENT_IPPORT joined.
$_672CLIENT_IPPORT Test
$_673CLIENT_IPPORT joined.
$_673CLIENT_IPPORT Test
$_674CLIENT_IPPORT joined.
$_674CLIENT_IPPORT Test
$_675CLIENT_IPPORT joined.
$_675CLIENT_IPPORT Test
$_676CLIENT_IPPORT joined.
$_676CLIENT_IPPORT Test
$_677CLIENT_IPPORT joined.
$_677CLIENT_IPPORT Test
$_678CLIENT_IPPORT joined.
$_678CLIENT_IPPORT Test
$_679CLIENT_IPPORT joined.
$_679CLIENT_IPPORT Test
$_680CLIENT_IPPORT joined.
$_680CLIENT_IPPORT Test
$_681CLIENT_IPPORT joined.
$_681CLIENT_IPPORT Test
$_682CLIENT_IPPORT joined.
$_682CLIENT_IPPORT Test
$_683CLIENT_IPPORT joined.
$_683CLIENT_IPPORT Test
$_684CLIENT_IPPORT joined.
$_684CLIENT_IPPORT Test
$_685CLIENT_IPPORT joined.
$_685CLIENT_IPPORT Test
$_686CLIENT_IPPORT joined.
$_686CLIENT_IPPORT Test
$_687CLIENT_IPPORT joined.
$_687CLIENT_IPPORT Test
$_688CLIENT_IPPORT joined.
$_688CLIENT_IPPORT Test
$_689CLIENT_IPPORT joined.
$_689CLIENT_IPPORT Test
$_690CLIENT_IPPORT joined.
$_690CLIENT_IPPORT Test
$_691CLIENT_IPPORT joined.
$_691CLIENT_IPPORT Test
$_692CLIENT_IPPORT joined.
$_692CLIENT_IPPORT Test
$_693CLIENT_IPPORT joined.
$_693CLIENT_IPPORT Test
$_694CLIENT_IPPORT joined.
$_694CLIENT_IPPORT Test
$_695CLIENT_IPPORT joined.
$_695CLIENT_IPPORT Test
$_696CLIENT_IPPORT joined.
$_696CLIENT_IPPORT Test
$_697CLIENT_IPPORT joined.
$_697CLIENT_IPPORT Test
$_698CLIENT_IPPORT joined.
$_698CLIENT_IPPORT Test
$_699CLIENT_IPPORT joined.
$_699CLIENT_IPPORT Test
$_700CLIENT_IPPORT joined.
$_700CLIENT_IPPORT Test
$_701CLIENT_IPPORT joined.
$_701CLIENT_IPPORT Test
$_702CLIENT_IPPORT joined.
$_702CLIENT_IPPORT Test
$_703CLIENT_IPPORT joined.
$_703CLIENT_IPPORT Test
$_704CLIENT_IPPORT joined.
$_704CLIENT_IPPORT Test
$_705CLIENT_IPPORT joined.
$_705CLIENT_IPPORT Test
$_706CLIENT_IPPORT joined.
$_706CLIENT_IPPORT Test
$_707CLIENT_IPPORT joined.
$_707CLIENT_IPPORT Test
$_708CLIENT_IPPORT joined.
$_708CLIENT_IPPORT Test
$_709CLIENT_IPPORT joined.
$_709CLIENT_IPPORT Test
$_710CLIENT_IPPORT joined.
$_710CLIENT_IPPORT Test
$_711CLIENT_IPPORT joined.
$_711CLIENT_IPPORT Test
$_712CLIENT_IPPORT joined.
$_712CLIENT_IPPORT Test
$_713CLIENT_IPPORT joined.
$_713CLIENT_IPPORT Test
$_714CLIENT_IPPORT joined.
$_714CLIENT_IPPORT Test
$_715CLIENT_IPPORT joined.
$_715CLIENT_IPPORT Test
$_716CLIENT_IPPORT joined.
$_716CLIENT_IPPORT Test
$_717CLIENT_IPPORT joined.
$_717CLIENT_IPPORT Test
$_718CLIENT_IPPORT joined.
$_718CLIENT_IPPORT Test
$_719CLIENT_IPPORT joined.
$_719CLIENT_IPPORT Test
$_720CLIENT_IPPORT joined.
$_720CLIENT_IPPORT Test
$_721CLIENT_IPPORT joined.
$_721CLIENT_IPPORT Test
$_722CLIENT_IPPORT joined.
$_722CLIENT_IPPORT Test
$_723CLIENT_IPPORT joined.
$_723CLIENT_IPPORT Test
$_724CLIENT_IPPORT joined.
$_724CLIENT_IPPORT Test
$_725CLIENT_IPPORT joined.
$_725CLIENT_IPPORT Test
$_726CLIENT_IPPORT joined.
$_726CLIENT_IPPORT Test
$_727CLIENT_IPPORT joined.
$_727CLIENT_IPPORT Test
$_728CLIENT_IPPORT joined.
$_728CLIENT_IPPORT Test
$_729CLIENT_IPPORT joined.
$_729CLIENT_IPPORT Test
$_730CLIENT_IPPORT joined.
$_730CLIENT_IPPORT Test
$_731CLIENT_IPPORT joined.
$_731CLIENT_IPPORT Test
$_732CLIENT_IPPORT joined.
$_732CLIENT_IPPORT Test
$_733CLIENT_IPPORT joined.
$_733CLIENT_IPPORT Test
$_734CLIENT_IPPORT joined.
$_734CLIENT_IPPORT Test
$_735CLIENT_IPPORT joined.
$_735CLIENT_IPPORT Test
$_736CLIENT_IPPORT joined.
$_736CLIENT_IPPORT Test
$_737CLIENT_IPPORT joined.
$_737CLIENT_IPPORT Test
$_738CLIENT_IPPORT joined.
$_738CLIENT_IPPORT Test
$_739CLIENT_IPPORT joined.
$_739CLIENT_IPPORT Test
$_740CLIENT_IPPORT joined.
$_740CLIENT_IPPORT Test
$_741CLIENT_IPPORT joined.
$_741CLIENT_IPPORT Test
$_742CLIENT_IPPORT joined.
$_742CLIENT_IPPORT Test
$_743CLIENT_IPPORT joined.
$_743CLIENT_IPPORT Test
$_744CLIENT_IPPORT joined.
$_744CLIENT_IPPORT Test
$_745CLIENT_IPPORT joined.
$_745CLIENT_IPPORT Test
$_746CLIENT_IPPORT joined.
$_746CLIENT_IPPORT Test
$_747CLIENT_IPPORT joined.
$_747CLIENT_IPPORT Test
$_748CLIENT_IPPORT joined.
$_748CLIENT_IPPORT Test
$_749CLIENT_IPPORT joined.
$_749CLIENT_IPPORT Test
$_750CLIENT_IPPORT joined.
$_750CLIENT_IPPORT Test
$_751CLIENT_IPPORT joined.
$_751CLIENT_IPPORT Test
$_752CLIENT_IPPORT joined.
$_752CLIENT_IPPORT Test
$_753CLIENT_IPPORT joined.
$_753CLIENT_IPPORT Test
$_754CLIENT_IPPORT joined.
$_754CLIENT_IPPORT Test
$_755CLIENT_IPPORT joined.
$_755CLIENT_IPPORT Test
$_756CLIENT_IPPORT joined.
$_756CLIENT_IPPORT Test
$_757CLIENT_IPPORT joined.
$_757CLIENT_IPPORT Test
$_758CLIENT_IPPORT joined.
$_758CLIENT_IPPORT Test
$_759CLIENT_IPPORT joined.
$_759CLIENT_IPPORT Test
$_760CLIENT_IPPORT joined.
$_760CLIENT_IPPORT Test
$_761CLIENT_IPPORT joined.
$_761CLIENT_IPPORT Test
$_762CLIENT_IPPORT joined.
$_762CLIENT_IPPORT Test
$_763CLIENT_IPPORT joined.
$_763CLIENT_IPPORT Test
$_764CLIENT_IPPORT joined.
$_764CLIENT_IPPORT Test
$_765CLIENT_IPPORT joined.
$_765CLIENT_IPPORT Test
$_766CLIENT_IPPORT joined.
$_766CLIENT_IPPORT Test
$_767CLIENT_IPPORT joined.
$_767CLIENT_IPPORT Test
$_768CLIENT_IPPORT joined.
$_768CLIENT_IPPORT Test
$_769CLIENT_IPPORT joined.
$_769CLIENT_IPPORT Test
$_770CLIENT_IPPORT joined.
$_770CLIENT_IPPORT Test
$_771CLIENT_IPPORT joined.
$_771CLIENT_IPPORT Test
$_772CLIENT_IPPORT joined.
$_772CLIENT_IPPORT Test
$_773CLIENT_IPPORT joined.
$_773CLIENT_IPPORT Test
$_774CLIENT_IPPORT joined.
$_774CLIENT_IPPORT Test
$_775CLIENT_IPPORT joined.
$_775CLIENT_IPPORT Test
$_776CLIENT_IPPORT joined.
$_776CLIENT_IPPORT Test
$_777CLIENT_IPPORT joined.
$_777CLIENT_IPPORT Test
$_778CLIENT_IPPORT joined.
$_778CLIENT_IPPORT Test
$_779CLIENT_IPPORT joined.
$_779CLIENT_IPPORT Test
$_780CLIENT_IPPORT joined.
$_780CLIENT_IPPORT Test
$_781CLIENT_IPPORT joined.
$_781CLIENT_IPPORT Test
$_782CLIENT_IPPORT joined.
$_782CLIENT_IPPORT Test
$_783CLIENT_IPPORT joined.
$_783CLIENT_IPPORT Test
$_784CLIENT_IPPORT joined.
$_784CLIENT_IPPORT Test
$_785CLIENT_IPPORT joined.
$_785CLIENT_IPPORT Test
$_786CLIENT_IPPORT joined.
$_786CLIENT_IPPORT Test
$_787CLIENT_IPPORT joined.
$_787CLIENT_IPPORT Test
$_788CLIENT_IPPORT joined.
$_788CLIENT_IPPORT Test
$_789CLIENT_IPPORT joined.
$_789CLIENT_IPPORT Test
$_790CLIENT_IPPORT joined.
$_790CLIENT_IPPORT Test
$_791CLIENT_IPPORT joined.
$_791CLIENT_IPPORT Test
$_792CLIENT_IPPORT joined.
$_792CLIENT_IPPORT Test
$_793CLIENT_IPPORT joined.
$_793CLIENT_IPPORT Test
$_794CLIENT_IPPORT joined.
$_794CLIENT_IPPORT Test
$_795CLIENT_IPPORT joined.
$_795CLIENT_IPPORT Test
$_796CLIENT_IPPORT joined.
$_796CLIENT_IPPORT Test
$_797CLIENT_IPPORT joined.
$_797CLIENT_IPPORT Test
$_798CLIENT_IPPORT joined.
$_798CLIENT_IPPORT Test
$_799CLIENT_IPPORT joined.
$_799CLIENT_IPPORT Test
$_800CLIENT_IPPORT joined.
$_800CLIENT_IPPORT Test
$_801CLIENT_IPPORT joined.
$_801CLIENT_IPPORT Test
$_802CLIENT_IPPORT joined.
$_802CLIENT_IPPORT Test
$_803CLIENT_IPPORT joined.
$_803CLIENT_IPPORT Test
$_804CLIENT_IPPORT joined.
$_804CLIENT_IPPORT Test
$_805CLIENT_IPPORT joined.
$_805CLIENT_IPPORT Test
$_806CLIENT_IPPORT joined.
$_806CLIENT_IPPORT Test
$_807CLIENT_IPPORT joined.
$_807CLIENT_IPPORT Test
$_808CLIENT_IPPORT joined.
$_808CLIENT_IPPORT Test
$_809CLIENT_IPPORT joined.
$_809CLIENT_IPPORT Test
$_810CLIENT_IPPORT joined.
$_810CLIENT_IPPORT Test
$_811CLIENT_IPPORT joined.
$_811CLIENT_IPPORT Test
$_812CLIENT_IPPORT joined.
$_812CLIENT_IPPORT Test
$_813CLIENT_IPPORT joined.
$_813CLIENT_IPPORT Test
$_814CLIENT_IPPORT joined.
$_814CLIENT_IPPORT Test
$_815CLIENT_IPPORT joined.
$_815CLIENT_IPPORT Test
$_816CLIENT_IPPORT joined.
$_816CLIENT_IPPORT Test
$_817CLIENT_IPPORT joined.
$_817CLIENT_IPPORT Test
$_818CLIENT_IPPORT joined.
$_818CLIENT_IPPORT Test
$_819CLIENT_IPPORT joined.
$_819CLIENT_IPPORT Test
$_820CLIENT_IPPORT joined.
$_820CLIENT_IPPORT Test
$_821CLIENT_IPPORT joined.
$_821CLIENT_IPPORT Test
$_822CLIENT_IPPORT joined.
$_822CLIENT_IPPORT Test
$_823CLIENT_IPPORT joined.
$_823CLIENT_IPPORT Test
$_824CLIENT_IPPORT joined.
$_824CLIENT_IPPORT Test
$_825CLIENT_IPPORT joined.
$_825CLIENT_IPPORT Test
$_826CLIENT_IPPORT joined.
$_826CLIENT_IPPORT Test
$_827CLIENT_IPPORT joined.
$_827CLIENT_IPPORT Test
$_828CLIENT_IPPORT joined.
$_828CLIENT_IPPORT Test
$_829CLIENT_IPPORT joined.
$_829CLIENT_IPPORT Test
$_830CLIENT_IPPORT joined.
$_830CLIENT_IPPORT Test
$_831CLIENT_IPPORT joined.
$_831CLIENT_IPPORT Test
$_832CLIENT_IPPORT joined.
$_832CLIENT_IPPORT Test
$_833CLIENT_IPPORT joined.
$_833CLIENT_IPPORT Test
$_834CLIENT_IPPORT joined.
$_834CLIENT_IPPORT Test
$_835CLIENT_IPPORT joined.
$_835CLIENT_IPPORT Test
$_836CLIENT_IPPORT joined.
$_836CLIENT_IPPORT Test
$_837CLIENT_IPPORT joined.
$_837CLIENT_IPPORT Test
$_838CLIENT_IPPORT joined.
$_838CLIENT_IPPORT Test
$_839CLIENT_IPPORT joined.
$_839CLIENT_IPPORT Test
$_840CLIENT_IPPORT joined.
$_840CLIENT_IPPORT Test
$_841CLIENT_IPPORT joined.
$_841CLIENT_IPPORT Test
$_842CLIENT_IPPORT joined.
$_842CLIENT_IPPORT Test
$_843CLIENT_IPPORT joined.
$_843CLIENT_IPPORT Test
$_844CLIENT_IPPORT joined.
$_844CLIENT_IPPORT Test
$_845CLIENT_IPPORT joined.
$_845CLIENT_IPPORT Test
$_846CLIENT_IPPORT joined.
$_846CLIENT_IPPORT Test
$_847CLIENT_IPPORT joined.
$_847CLIENT_IPPORT Test
$_848CLIENT_IPPORT joined.
$_848CLIENT_IPPORT Test
$_849CLIENT_IPPORT joined.
$_849CLIENT_IPPORT Test
$_850CLIENT_IPPORT joined.
$_850CLIENT_IPPORT Test
$_851CLIENT_IPPORT joined.
$_851CLIENT_IPPORT Test
$_852CLIENT_IPPORT joined.
$_852CLIENT_IPPORT Test
$_853CLIENT_IPPORT joined.
$_853CLIENT_IPPORT Test
$_854CLIENT_IPPORT joined.
$_854CLIENT_IPPORT Test
$_855CLIENT_IPPORT joined.
$_855CLIENT_IPPORT Test
$_856CLIENT_IPPORT joined.
$_856CLIENT_IPPORT Test
$_857CLIENT_IPPORT joined.
$_857CLIENT_IPPORT Test
$_858CLIENT_IPPORT joined.
$_858CLIENT_IPPORT Test
$_859CLIENT_IPPORT joined.
$_859CLIENT_IPPORT Test
$_860CLIENT_IPPORT joined.
$_860CLIENT_IPPORT Test
$_861CLIENT_IPPORT joined.
$_861CLIENT_IPPORT Test
$_862CLIENT_IPPORT joined.
$_862CLIENT_IPPORT Test
$_863CLIENT_IPPORT joined.
$_863CLIENT_IPPORT Test
$_864CLIENT_IPPORT joined.
$_864CLIENT_IPPORT Test
$_865CLIENT_IPPORT joined.
$_865CLIENT_IPPORT Test
$_866CLIENT_IPPORT joined.
$_866CLIENT_IPPORT Test
$_867CLIENT_IPPORT joined.
$_867CLIENT_IPPORT Test
$_868CLIENT_IPPORT joined.
$_868CLIENT_IPPORT Test
$_869CLIENT_IPPORT joined.
$_869CLIENT_IPPORT Test
$_870CLIENT_IPPORT joined.
$_870CLIENT_IPPORT Test
$_871CLIENT_IPPORT joined.
$_871CLIENT_IPPORT Test
$_872CLIENT_IPPORT joined.
$_872CLIENT_IPPORT Test
$_873CLIENT_IPPORT joined.
$_873CLIENT_IPPORT Test
$_874CLIENT_IPPORT joined.
$_874CLIENT_IPPORT Test
$_875CLIENT_IPPORT joined.
$_875CLIENT_IPPORT Test
$_876CLIENT_IPPORT joined.
$_876CLIENT_IPPORT Test
$_877CLIENT_IPPORT joined.
$_877CLIENT_IPPORT Test
$_878CLIENT_IPPORT joined.
$_878CLIENT_IPPORT Test
$_879CLIENT_IPPORT joined.
$_879CLIENT_IPPORT Test
$_880CLIENT_IPPORT joined.
$_880CLIENT_IPPORT Test
$_881CLIENT_IPPORT joined.
$_881CLIENT_IPPORT Test
$_882CLIENT_IPPORT joined.
$_882CLIENT_IPPORT Test
$_883CLIENT_IPPORT joined.
$_883CLIENT_IPPORT Test
$_884CLIENT_IPPORT joined.
$_884CLIENT_IPPORT Test
$_885CLIENT_IPPORT joined.
$_885CLIENT_IPPORT Test
$_886CLIENT_IPPORT joined.
$_886CLIENT_IPPORT Test
$_887CLIENT_IPPORT joined.
$_887CLIENT_IPPORT Test
$_888CLIENT_IPPORT joined.
$_888CLIENT_IPPORT Test
$_889CLIENT_IPPORT joined.
$_889CLIENT_IPPORT Test
$_890CLIENT_IPPORT joined.
$_890CLIENT_IPPORT Test
$_891CLIENT_IPPORT joined.
$_891CLIENT_IPPORT Test
$_892CLIENT_IPPORT joined.
$_892CLIENT_IPPORT Test
$_893CLIENT_IPPORT joined.
$_893CLIENT_IPPORT Test
$_894CLIENT_IPPORT joined.
$_894CLIENT_IPPORT Test
$_895CLIENT_IPPORT joined.
$_895CLIENT_IPPORT Test
$_896CLIENT_IPPORT joined.
$_896CLIENT_IPPORT Test
$_897CLIENT_IPPORT joined.
$_897CLIENT_IPPORT Test
$_898CLIENT_IPPORT joined.
$_898CLIENT_IPPORT Test
$_899CLIENT_IPPORT joined.
$_899CLIENT_IPPORT Test
$_900CLIENT_IPPORT joined.
$_900CLIENT_IPPORT Test
$_901CLIENT_IPPORT joined.
$_901CLIENT_IPPORT Test
$_902CLIENT_IPPORT joined.
$_902CLIENT_IPPORT Test
$_903CLIENT_IPPORT joined.
$_903CLIENT_IPPORT Test
$_904CLIENT_IPPORT joined.
$_904CLIENT_IPPORT Test
$_905CLIENT_IPPORT joined.
$_905CLIENT_IPPORT Test
$_906CLIENT_IPPORT joined.
$_906CLIENT_IPPORT Test
$_907CLIENT_IPPORT joined.
$_907CLIENT_IPPORT Test
$_908CLIENT_IPPORT joined.
$_908CLIENT_IPPORT Test
$_909CLIENT_IPPORT joined.
$_909CLIENT_IPPORT Test
$_910CLIENT_IPPORT joined.
$_910CLIENT_IPPORT Test
$_911CLIENT_IPPORT joined.
$_911CLIENT_IPPORT Test
$_912CLIENT_IPPORT joined.
$_912CLIENT_IPPORT Test
$_913CLIENT_IPPORT joined.
$_913CLIENT_IPPORT Test
$_914CLIENT_IPPORT joined.
$_914CLIENT_IPPORT Test
$_915CLIENT_IPPORT joined.
$_915CLIENT_IPPORT Test
$_916CLIENT_IPPORT joined.
$_916CLIENT_IPPORT Test
$_917CLIENT_IPPORT joined.
$_917CLIENT_IPPORT Test
$_918CLIENT_IPPORT joined.
$_918CLIENT_IPPORT Test
$_919CLIENT_IPPORT joined.
$_919CLIENT_IPPORT Test
$_920CLIENT_IPPORT joined.
$_920CLIENT_IPPORT Test
$_921CLIENT_IPPORT joined.
$_921CLIENT_IPPORT Test
$_922CLIENT_IPPORT joined.
$_922CLIENT_IPPORT Test
$_923CLIENT_IPPORT joined.
$_923CLIENT_IPPORT Test
$_924CLIENT_IPPORT joined.
$_924CLIENT_IPPORT Test
$_925CLIENT_IPPORT joined.
$_925CLIENT_IPPORT Test
$_926CLIENT_IPPORT joined.
$_926CLIENT_IPPORT Test
$_927CLIENT_IPPORT joined.
$_927CLIENT_IPPORT Test
$_928CLIENT_IPPORT joined.
$_928CLIENT_IPPORT Test
$_929CLIENT_IPPORT joined.
$_929CLIENT_IPPORT Test
$_930CLIENT_IPPORT joined.
$_930CLIENT_IPPORT Test
$_931CLIENT_IPPORT joined.
$_931CLIENT_IPPORT Test
$_932CLIENT_IPPORT joined.
$_932CLIENT_IPPORT Test
$_933CLIENT_IPPORT joined.
$_933CLIENT_IPPORT Test
$_934CLIENT_IPPORT joined.
$_934CLIENT_IPPORT Test
$_935CLIENT_IPPORT joined.
$_935CLIENT_IPPORT Test
$_936CLIENT_IPPORT joined.
$_936CLIENT_IPPORT Test
$_937CLIENT_IPPORT joined.
$_937CLIENT_IPPORT Test
$_938CLIENT_IPPORT joined.
$_938CLIENT_IPPORT Test
$_939CLIENT_IPPORT joined.
$_939CLIENT_IPPORT Test
$_940CLIENT_IPPORT joined.
$_940CLIENT_IPPORT Test
$_941CLIENT_IPPORT joined.
$_941CLIENT_IPPORT Test
$_942CLIENT_IPPORT joined.
$_942CLIENT_IPPORT Test
$_943CLIENT_IPPORT joined.
$_943CLIENT_IPPORT Test
$_944CLIENT_IPPORT joined.
$_944CLIENT_IPPORT Test
$_945CLIENT_IPPORT joined.
$_945CLIENT_IPPORT Test
$_946CLIENT_IPPORT joined.
$_946CLIENT_IPPORT Test
$_947CLIENT_IPPORT joined.
$_947CLIENT_IPPORT Test
$_948CLIENT_IPPORT joined.
$_948CLIENT_IPPORT Test
$_949CLIENT_IPPORT joined.
$_949CLIENT_IPPORT Test
$_950CLIENT_IPPORT joined.
$_950CLIENT_IPPORT Test
$_951CLIENT_IPPORT joined.
$_951CLIENT_IPPORT Test
$_952CLIENT_IPPORT joined.
$_952CLIENT_IPPORT Test
$_953CLIENT_IPPORT joined.
$_953CLIENT_IPPORT Test
$_954CLIENT_IPPORT joined.
$_954CLIENT_IPPORT Test
$_955CLIENT_IPPORT joined.
$_955CLIENT_IPPORT Test
$_956CLIENT_IPPORT joined.
$_956CLIENT_IPPORT Test
$_957CLIENT_IPPORT joined.
$_957CLIENT_IPPORT Test
$_958CLIENT_IPPORT joined.
$_958CLIENT_IPPORT Test
$_959CLIENT_IPPORT joined.
$_959CLIENT_IPPORT Test
$_960CLIENT_IPPORT joined.
$_960CLIENT_IPPORT Test
$_961CLIENT_IPPORT joined.
$_961CLIENT_IPPORT Test
$_962CLIENT_IPPORT joined.
$_962CLIENT_IPPORT Test
$_963CLIENT_IPPORT joined.
$_963CLIENT_IPPORT Test
$_964CLIENT_IPPORT joined.
$_964CLIENT_IPPORT Test
$_965CLIENT_IPPORT joined.
$_965CLIENT_IPPORT Test
$_966CLIENT_IPPORT joined.
$_966CLIENT_IPPORT Test
$_967CLIENT_IPPORT joined.
$_967CLIENT_IPPORT Test
$_968CLIENT_IPPORT joined.
$_968CLIENT_IPPORT Test
$_969CLIENT_IPPORT joined.
$_969CLIENT_IPPORT Test
$_970CLIENT_IPPORT joined.
$_970CLIENT_IPPORT Test
$_971CLIENT_IPPORT joined.
$_971CLIENT_IPPORT Test
$_972CLIENT_IPPORT joined.
$_972CLIENT_IPPORT Test
$_973CLIENT_IPPORT joined.
$_973CLIENT_IPPORT Test
$_974CLIENT_IPPORT joined.
$_974CLIENT_IPPORT Test
$_975CLIENT_IPPORT joined.
$_975CLIENT_IPPORT Test
$_976CLIENT_IPPORT joined.
$_976CLIENT_IPPORT Test
$_977CLIENT_IPPORT joined.
$_977CLIENT_IPPORT Test
$_978CLIENT_IPPORT joined.
$_978CLIENT_IPPORT Test
$_979CLIENT_IPPORT joined.
$_979CLIENT_IPPORT Test
$_980CLIENT_IPPORT joined.
$_980CLIENT_IPPORT Test
$_981CLIENT_IPPORT joined.
$_981CLIENT_IPPORT Test
$_982CLIENT_IPPORT joined.
$_982CLIENT_IPPORT Test
$_983CLIENT_IPPORT joined.
$_983CLIENT_IPPORT Test
$_984CLIENT_IPPORT joined.
$_984CLIENT_IPPORT Test
$_985CLIENT_IPPORT joined.
$_985CLIENT_IPPORT Test
$_986CLIENT_IPPORT joined.
$_986CLIENT_IPPORT Test
$_987CLIENT_IPPORT joined.
$_987CLIENT_IPPORT Test
$_988CLIENT_IPPORT joined.
$_988CLIENT_IPPORT Test
$_989CLIENT_IPPORT joined.
$_989CLIENT_IPPORT Test
$_990CLIENT_IPPORT joined.
$_990CLIENT_IPPORT Test
$_991CLIENT_IPPORT joined.
$_991CLIENT_IPPORT Test
$_992CLIENT_IPPORT joined.
$_992CLIENT_IPPORT Test
$_993CLIENT_IPPORT joined.
$_993CLIENT_IPPORT Test
$_994CLIENT_IPPORT joined.
$_994CLIENT_IPPORT Test
$_995CLIENT_IPPORT joined.
$_995CLIENT_IPPORT Test
$_996CLIENT_IPPORT joined.
$_996CLIENT_IPPORT Test
$_997CLIENT_IPPORT joined.
$_997CLIENT_IPPORT Test
$_998CLIENT_IPPORT joined.
$_998CLIENT_IPPORT Test
EOF
then
  echo OK
else
  echo FAIL
  exit
fi

echo "Finished Big Clients test."
