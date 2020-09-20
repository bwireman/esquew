#!/bin/bash

launchEsquew() {
    ## This is stupid but it works...
    echo "Starting esquew..."
    elixir -e "File.write! 'pid', :os.getpid" -S mix run --no-halt &
}

runBench() {
    echo "Running bench"
    echo "3..."
    sleep .5
    echo "2..."
    sleep .5
    echo "1..."
    sleep .5
    echo 🚀
    go run testRun/main.go
}

killEsquew() {
    echo "Killing esquew..."
    kill -9 $(cat pid)
    echo "☠️"
}

launchEsquew
runBench
killEsquew
rm pid
