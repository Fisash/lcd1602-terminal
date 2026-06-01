#include "base/syscalls.h"
#include "converter.h"

/*convert byte to hex number view
 put it in buffer pointer addres and one next byte*/
static const char hex_chars [] = "0123456789ABCDEF";
void byte_to_hex(unsigned char byte, char* buffer)
{
    buffer[0] = hex_chars[byte >> 4];
    buffer[1] = hex_chars[byte & 0b00001111];    
}

