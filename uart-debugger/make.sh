#!/bin/bash
set -e

SRC_DIR=src
OUT_DIR=out
BASE_DIR="$SRC_DIR/base"   

mkdir -p "$OUT_DIR"

ASM1="$BASE_DIR/start.asm"
ASM2="$BASE_DIR/syscalls.asm"

if [ ! -f "$ASM1" ]; then
    echo "Error: $ASM1 not found"
    exit 1
fi
if [ ! -f "$ASM2" ]; then
    echo "Error: $ASM2 not found"
    exit 1
fi

echo "=== Assembling base files ==="
nasm -f elf32 -g -F dwarf "$ASM1" -o "$OUT_DIR/start.o"
echo "  $ASM1 -> $OUT_DIR/start.o"

nasm -f elf32 -g -F dwarf "$ASM2" -o "$OUT_DIR/syscalls.o"
echo "  $ASM2 -> $OUT_DIR/syscalls.o"

shopt -s nullglob
C_FILES=("$SRC_DIR"/*.c)

if [ ${#C_FILES[@]} -eq 0 ]; then
    echo "Error: no .c files found in $SRC_DIR"
    exit 1
fi

OBJ_FILES=("$OUT_DIR/start.o" "$OUT_DIR/syscalls.o")

echo "=== Compiling C sources ==="
for cfile in "${C_FILES[@]}"; do
    obj="$OUT_DIR/$(basename "${cfile%.c}.o")"
    echo "  $cfile -> $obj"
    gcc -m32 -Wall -nostdlib -ffreestanding -fno-stack-protector -fno-builtin -static -c "$cfile" -o "$obj"
    OBJ_FILES+=("$obj")
done

echo "=== Linking ==="
ld -m elf_i386 -strip-all -o "$OUT_DIR/main" "${OBJ_FILES[@]}"

echo "Build successful: $OUT_DIR/main"
