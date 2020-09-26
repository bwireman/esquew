#!/bin/bash

RET_VALUE=0

echoSleep() {
    echo $1
    sleep .5
}

launchEsquew() {
    ## This is stupid but it works...
    echo "Starting esquew..."
    elixir -e "File.write! 'pid', :os.getpid" -S mix run --no-halt &
}

run() {
    echoSleep "test run"
    echoSleep "3..."
    echoSleep "2..."
    echoSleep "1..."
    echoSleep 🚀
    go run testRun/main.go
    RET_VALUE=$?
}

killEsquew() {
    echoSleep "Killing esquew..."
    kill -9 $(cat pid)
    echo "☠️"
}

launchEsquew
run
killEsquew
rm pid
exit $RET_VALUE