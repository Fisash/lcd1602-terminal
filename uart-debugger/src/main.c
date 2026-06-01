#include "base/syscalls.h"
#include "parser.h"

#define READ_BUF_SIZE 32

static const char argc_error [] = "Give me device path in argument\n";
static const char open_device_error [] = "Can`t open device!\n";
static const char read_device_error [] = "Can`t read device!\n";
static const char start_text [] = "Starting terminal debugger in device ";

static int string_length(const char *s)
{
    int i = 0;
    while(s[i])
        i++;
    return i;
}

static void read_device_loop(int fd) 
{
    char read_buffer[READ_BUF_SIZE];
    int read_res, i;
    while (1)
    { 
        read_res = sys_read(fd, read_buffer, READ_BUF_SIZE);
        if (read_res <= 0)
        {
            sys_write(1, read_device_error, sizeof(read_device_error)-1);
            sys_close(fd);
            return;
        }

        for(i = 0; i < read_res; i++)
            parse_byte(read_buffer[i]);
    }
}

int main(int argc, char **argv)
{
    if(argc < 2) {
        sys_write(1, argc_error, sizeof(argc_error)-1);
        return 1;
    }
    
    const char* device_name = argv[1];

    int fd = sys_open(device_name, 0, 0);
    if (fd == -1)
    {
        sys_write(1, open_device_error, sizeof(open_device_error));
        return 1;
    }

    sys_write(1, start_text, sizeof(start_text)-1);
    sys_write(1, device_name, string_length(device_name));
    sys_write(1, "!\n", 2);

    read_device_loop(fd);
    return 0;
}

