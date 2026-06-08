#!/bin/bash

DEVICE="/dev/ttyUSB16"
BAUD="9600"
MARKER="---EOF---"

stty -F "$DEVICE" "$BAUD" raw -echo -echoe -echok -hupcl clocal

coproc LCDTERMBASH { stdbuf -oL bash --norc --noprofile 2>&1; }
echo "LCD terminal started. Bash PID: $LCDTERMBASH_PID"

exec 3< "$DEVICE"
exec 4> "$DEVICE"

while read -r cmd <&3; do
    cmd="${cmd%$'\r'}"
    [ -z "$cmd" ] && continue

    echo "Got command: [$cmd]"

    echo "$cmd" >&${LCDTERMBASH[1]}
    echo "echo '$MARKER'" >&${LCDTERMBASH[1]}

    while read -r output <&${LCDTERMBASH[0]}; do
        [ "$output" = "$MARKER" ] && break
        output="${output%$'\r'}"
        [ -z "$output" ] && continue
        echo -n "$output" >&4
    done

    printf '\x04' >&4
    echo "--- Answer sended ---"
done
