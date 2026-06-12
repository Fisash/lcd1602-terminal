## Current hardware installation:

i2c (in my case stitched with lcd): <br/>
sda - a4 <br/>
scl - a5 <br/>
gnd - gnd <br/>
vcc- 5v <br/>

tact buttons: in pin range d2-d9 (and other side to gnd) for typing chars <br/>
and d10 for send button

##Install the required packages (arch):

```bash
sudo pacman -S avr-binutils avr-gcc avrdude
```
##Build and flash
(you'll probably have to change the device file name to yours in the build script, as I was too lazy to take it out)
```bash
cd firmware
./make.sh
```

## Protocol
when you press the send button, the device sends a buffer with typed characters (from the used part of the lcd input lint buffer) via uart, after which it sends the end-of-line byte (0x0a). <br/>
after that, the device goes into reading answer mode, it reads all bytes sent by the host via uart to the lcd output line buffer, finally, when byte 0x04 arrives, it draws the content of the lcd output line buffer on the lcd and goes to to typyng mode. 
