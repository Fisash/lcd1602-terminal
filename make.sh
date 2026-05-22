#!/bin/bash
avr-gcc -x assembler-with-cpp -mmcu=atmega328p -c main.asm -o main.o
avr-gcc -x assembler-with-cpp -mmcu=atmega328p -c delay.asm -o delay.o
avr-gcc -x assembler-with-cpp -mmcu=atmega328p -c i2c.asm -o i2c.o
avr-gcc -x assembler-with-cpp -mmcu=atmega328p -c lcd.asm -o lcd.o
avr-gcc -x assembler-with-cpp -mmcu=atmega328p -c uart.asm -o uart.o
avr-gcc -x assembler-with-cpp -mmcu=atmega328p -c typer.asm -o typer.o
    
avr-gcc -mmcu=atmega328p delay.o typer.o i2c.o lcd.o uart.o main.o -o main.elf

avr-objcopy -O ihex main.elf main.hex
avrdude -c arduino -p m328p -P /dev/ttyUSB0 -b 115200 -U flash:w:main.hex:i
