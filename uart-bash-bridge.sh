#!/bin/bash

coproc LCDTERMBASH { stdbuf -oL bash 2>&1; }

MARKER="---EOF---"

echo "Starting LCD terminal. Bash PID: $LCDTERMBASH_PID"
read cmd

echo "$cmd" >&"${LCDTERMBASH[1]}"
echo "echo '$MARKER'" >&"${LCDTERMBASH[1]}"


while read -r -u "${LCDTERMBASH[0]}" output; do
    output=$(echo "$output" | tr -d '\r')
    
    if [ "$output" = "$MARKER" ]; then
        break
    fi
    
    echo "$output" > /dev/ttyUSB0
    echo "--- answer was sended to lcd ---"
done

echo "exit" >&"${LCDTERMBASH[1]}"
