#!/bin/bash
set -e  

MCU=atmega328p
SRC_DIR=src
OUT_DIR=out

DEFINES=""

while getopts "d" opt; do
  case ${opt} in
    d )
      DEFINES="-DDEBUG"
      echo "=== Debug mode enabled ==="
      ;;
    \? )
      echo "Usage: $0 [-d]"
      exit 1
      ;;
  esac
done

mkdir -p "$OUT_DIR"

shopt -s nullglob
ASM_FILES=("$SRC_DIR"/*.asm)

if [ ${#ASM_FILES[@]} -eq 0 ]; then
    echo "Error: there are no .asm files in $SRC_DIR directory"
    exit 1
fi

OBJ_FILES=()

echo "=== Compilation ==="
for asm in "${ASM_FILES[@]}"; do
    obj="$OUT_DIR/$(basename "${asm%.asm}.o")"
    echo "  $asm -> $obj"
    avr-gcc -x assembler-with-cpp $DEFINES -mmcu="$MCU" -I"$SRC_DIR" -c "$asm" -o "$obj"
    OBJ_FILES+=("$obj")
done

echo "=== Linking  ==="
avr-gcc -mmcu="$MCU" "${OBJ_FILES[@]}" -o "$OUT_DIR/main.elf"

echo "=== Generataring hex ==="
avr-objcopy -O ihex "$OUT_DIR/main.elf" "$OUT_DIR/main.hex"

echo "=== Firmwaring ==="
avrdude -c arduino -p m328p -P /dev/ttyUSB13 -b 115200 -U flash:w:"$OUT_DIR/main.hex":i
