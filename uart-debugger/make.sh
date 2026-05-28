#!/bin/bash
set -e  

SRC_DIR=src
OUT_DIR=out

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
    nasm -f elf32 -g -F dwarf -I"$SRC_DIR" "$asm" -o "$obj"
    OBJ_FILES+=("$obj")
done

echo "=== Linking  ==="
ld -m elf_i386 "${OBJ_FILES[@]}" -o "$OUT_DIR/main"
