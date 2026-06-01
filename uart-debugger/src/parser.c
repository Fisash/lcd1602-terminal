#include "base/syscalls.h"
#include "parser.h"
#include "converter.h"

typedef enum InputState
{
     SequencePrefix,
     SequenceID,
     CursorData,
     FrameBufferData
} InputState;

static InputState input_state = SequencePrefix;
static int iterator = 0;

/* SEQUENCE PREFIX STATE*/
static const char sequence_prefix [] = "/^m[";
static int is_match_for_prefix(char byte)
{
    return byte == sequence_prefix[iterator];
}

static void parse_byte_sequence_prefix_state(char byte)
{
    if (is_match_for_prefix(byte))
    {
        iterator++;
        if (iterator == 4)
        {
            input_state = SequenceID;
            iterator = 0;
        }
    }
    else
        iterator = is_match_for_prefix(byte);
}

/* SEQUENCE ID STATE*/
static char state_id_buf[3];

static const char start_cursor_state_msg [] = "\nCursor addres: ";
static const char start_framebuf_state_msg [] = "\nFrame buffer: ";

int is_equal(const char* a, const char* b, unsigned int size)
{
    int i = 0;
    while (a[i] == b[i])
    {
        i++;
        if(i == size)
            return 1;
    }
    return 0;
}

static void select_data_state()
{
    if (is_equal(state_id_buf, "CUR", 3))
    {
        sys_write(1, start_cursor_state_msg, sizeof(start_cursor_state_msg)-1);
        input_state = CursorData;
    }

    else if (is_equal(state_id_buf, "BUF", 3))
    {
        sys_write(1, start_framebuf_state_msg, sizeof(start_framebuf_state_msg)-1);
        input_state = FrameBufferData;
    }
    else 
    {
        input_state = SequencePrefix;
    }
}

static void parse_byte_sequence_id_state(char byte)
{
    state_id_buf[iterator] = byte;
    iterator++;
    if(iterator == 3)
    {
        select_data_state();
        iterator = 0;
    }
}

/* CURSOR DATA STATE*/
static char cursor_data_buf[5];
static void parse_byte_cursor_state(char byte)
{
    byte_to_hex(byte, &cursor_data_buf[iterator]);

    if(iterator == 0)
        iterator += 3;
    else
    {
        cursor_data_buf[2] = ' ';
        sys_write(1, cursor_data_buf, 5);
        input_state = SequencePrefix;
        iterator = 0;
    }
}

/* FRAME BUFFER DATA STATE*/
static char framebuf_data_buf[19];
static char framebuf_data_dump_buf[32];

static void parse_byte_framebuf_state(char byte)
{
    framebuf_data_buf[iterator+1] = byte;
    byte_to_hex(byte, &framebuf_data_dump_buf[iterator*2]);
    iterator++;
    if(iterator == 16)
    {
        framebuf_data_buf[0] = '"';
        framebuf_data_buf[17] = '"';
        framebuf_data_buf[18] = '\n';

        sys_write(1, framebuf_data_buf, 19);
        sys_write(1, framebuf_data_dump_buf, 32);
        input_state = SequencePrefix;
        iterator = 0;
    }
}

void parse_byte(char byte)
{
    switch(input_state)
    {
        case SequencePrefix:
            parse_byte_sequence_prefix_state(byte);
            break;
        case SequenceID:
            parse_byte_sequence_id_state(byte);
            break;
        case CursorData:
            parse_byte_cursor_state(byte);
            break;
        case FrameBufferData:
            parse_byte_framebuf_state(byte);
            break;
    } 
}
