#!/bin/bash

DEVICE="/dev/ttyUSB16"
BAUD="9600"
MARKER="---EOF---"

stty -F "$DEVICE" "$BAUD" raw -echo -echoe -echok -hupcl clocal min 1 time 0

coproc LCDTERMBASH { stdbuf -oL bash --norc --noprofile 2>&1; }
echo "Starting LCD terminal. Bash PID: $LCDTERMBASH_PID"

exec 3< "$DEVICE"

while true; do
    cmd=""
    
    IFS= read -r -n 1 -u 3 char
    cmd="$cmd$char"
    while true; do
        IFS= read -r -n 1 -u 3 char
        if [ -z "$char" ]; then
            break
        fi
        cmd="$cmd$char"
    done

    cmd=$(echo "$cmd" | tr -d '\r\n')
    if [ -z "$cmd" ]; then
        continue
    fi

    echo "Получена команда: [$cmd]"

    echo "$cmd" >&"${LCDTERMBASH[1]}"
    echo "echo '$MARKER'" >&"${LCDTERMBASH[1]}"

    while read -r -u "${LCDTERMBASH[0]}" output; do
        if [ "$output" = "$MARKER" ]; then
            break
        fi

        output=$(echo "$output" | tr -d '\r\n')
        [ -z "$output" ] && continue

        echo "Отладка: отправляю в порт строку [$output]"
        sleep 0.5
        echo -n "$output" > "$DEVICE"
    done

    sleep 1.0
    echo "Отладка: отправляю маркер 0x04"
    printf "\x04" > "$DEVICE"
    
    echo "--- Ответ отправлен на LCD ---"
done

exec 3>&-
