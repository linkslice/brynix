// kernel.c - BRYNIX 64 C64-style kernel with keyboard
#include <stdint.h>

// Define size_t for freestanding environment
typedef unsigned long size_t;

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_MEMORY 0xB8000

// VGA colors
enum vga_color {
    VGA_COLOR_BLACK = 0,
    VGA_COLOR_BLUE = 1,
    VGA_COLOR_GREEN = 2,
    VGA_COLOR_CYAN = 3,
    VGA_COLOR_RED = 4,
    VGA_COLOR_MAGENTA = 5,
    VGA_COLOR_BROWN = 6,
    VGA_COLOR_LIGHT_GREY = 7,
    VGA_COLOR_DARK_GREY = 8,
    VGA_COLOR_LIGHT_BLUE = 9,
    VGA_COLOR_LIGHT_GREEN = 10,
    VGA_COLOR_LIGHT_CYAN = 11,
    VGA_COLOR_LIGHT_RED = 12,
    VGA_COLOR_LIGHT_MAGENTA = 13,
    VGA_COLOR_LIGHT_BROWN = 14,
    VGA_COLOR_WHITE = 15,
};

static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg) {
    return fg | bg << 4;
}

static inline uint16_t vga_entry(unsigned char uc, uint8_t color) {
    return (uint16_t) uc | (uint16_t) color << 8;
}

// Port I/O functions
static inline uint8_t inb(uint16_t port) {
    uint8_t result;
    __asm__ volatile ("inb %1, %0" : "=a"(result) : "Nd"(port));
    return result;
}

static inline void outb(uint16_t port, uint8_t value) {
    __asm__ volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}

// Terminal state
static size_t terminal_row;
static size_t terminal_column;
static uint8_t terminal_color;
static uint16_t* terminal_buffer;

// Cursor control
static uint8_t cursor_ready = 0;  // Don't show cursor until ready for input

// Function prototypes
void terminal_putchar(char c);
void terminal_write(const char* data, size_t size);
void terminal_writestring(const char* data);

void terminal_initialize(void) {
    terminal_row = 0;
    terminal_column = 0;
    terminal_color = vga_entry_color(VGA_COLOR_LIGHT_CYAN, VGA_COLOR_BLUE);  // C64 colors!
    terminal_buffer = (uint16_t*) VGA_MEMORY;
    
    // Disable hardware cursor
    outb(0x3D4, 0x0A);  // Cursor start register
    outb(0x3D5, 0x20);  // Disable cursor (bit 5 = 1)
    
    // Fill entire screen with C64 blue background
    for (size_t y = 0; y < VGA_HEIGHT; y++) {
        for (size_t x = 0; x < VGA_WIDTH; x++) {
            const size_t index = y * VGA_WIDTH + x;
            terminal_buffer[index] = vga_entry(' ', terminal_color);
        }
    }
}

void terminal_putchar(char c) {
    if (c == '\n') {
        terminal_column = 0;
        if (++terminal_row == VGA_HEIGHT) {
            terminal_row = 0;
        }
        return;
    }
    
    terminal_buffer[terminal_row * VGA_WIDTH + terminal_column] = vga_entry(c, terminal_color);
    if (++terminal_column == VGA_WIDTH) {
        terminal_column = 0;
        if (++terminal_row == VGA_HEIGHT) {
            terminal_row = 0;
        }
    }
}

void terminal_write(const char* data, size_t size) {
    for (size_t i = 0; i < size; i++)
        terminal_putchar(data[i]);
}

void terminal_writestring(const char* data) {
    size_t len = 0;
    while (data[len]) len++;  // strlen
    terminal_write(data, len);
}

// Input handling
#define INPUT_BUFFER_SIZE 80
static char input_buffer[INPUT_BUFFER_SIZE];
static size_t input_length = 0;

// Simple scancode to ASCII mapping (comprehensive)
char scancode_to_char(uint8_t scancode) {
    switch(scancode) {
        // Letters
        case 0x1E: return 'a';    case 0x30: return 'b';    case 0x2E: return 'c';
        case 0x20: return 'd';    case 0x12: return 'e';    case 0x21: return 'f';
        case 0x22: return 'g';    case 0x23: return 'h';    case 0x17: return 'i';
        case 0x24: return 'j';    case 0x25: return 'k';    case 0x26: return 'l';
        case 0x32: return 'm';    case 0x31: return 'n';    case 0x18: return 'o';
        case 0x19: return 'p';    case 0x10: return 'q';    case 0x13: return 'r';
        case 0x1F: return 's';    case 0x14: return 't';    case 0x16: return 'u';
        case 0x2F: return 'v';    case 0x11: return 'w';    case 0x2D: return 'x';
        case 0x15: return 'y';    case 0x2C: return 'z';
        
        // Numbers
        case 0x02: return '1';    case 0x03: return '2';    case 0x04: return '3';
        case 0x05: return '4';    case 0x06: return '5';    case 0x07: return '6';
        case 0x08: return '7';    case 0x09: return '8';    case 0x0A: return '9';
        case 0x0B: return '0';
        
        // Special keys
        case 0x39: return ' ';    // Space
        case 0x1C: return '\n';   // Enter
        case 0x0E: return '\b';   // Backspace
        
        default: return 0;
    }
}

void process_command(const char* cmd) {
    terminal_writestring("\n");
    
    if (cmd[0] == '\0') {
        // Empty command
    } else if (cmd[0] == 'h' && cmd[1] == 'e' && cmd[2] == 'l' && cmd[3] == 'p') {
        terminal_writestring("BRYNIX 64 BASIC COMMANDS:\n");
        terminal_writestring("  HELP - SHOW THIS HELP\n");
        terminal_writestring("  HELLO - GREETING\n");
        terminal_writestring("  CLS - CLEAR SCREEN\n");
    } else if (cmd[0] == 'h' && cmd[1] == 'e' && cmd[2] == 'l' && cmd[3] == 'l' && cmd[4] == 'o') {
        terminal_writestring("HELLO FROM BRYNIX 64!\n");
    } else if (cmd[0] == 'c' && cmd[1] == 'l' && cmd[2] == 's') {
        terminal_initialize();
        terminal_writestring("BRYNIX 64 READY.\n");
    } else {
        terminal_writestring("?SYNTAX ERROR\n");
    }
    
    terminal_writestring("\nREADY.\n>");
}

// Main kernel function
void kernel_main(void) {
    // Initialize terminal
    terminal_initialize();
    
    // Boot sequence
    terminal_writestring("    **** BRYNIX 64 KERNEL V1.0 ****\n\n");
    terminal_writestring("64K RAM SYSTEM  38911 BASIC BYTES FREE\n\n");
    terminal_writestring("READY.\n");
    terminal_writestring("LOAD\"KERNEL\",8,1\n");
    terminal_writestring("SEARCHING FOR KERNEL\n");
    terminal_writestring("LOADING\n");
    terminal_writestring("READY.\n");
    terminal_writestring("RUN\n\n");
    
    terminal_writestring("BRYNIX KERNEL INITIALIZED\n");
    terminal_writestring("- 64-BIT MODE: ACTIVE\n");
    terminal_writestring("- BASIC DISPLAY: READY\n");
    terminal_writestring("- KEYBOARD: POLLING MODE\n");
    terminal_writestring("- SYSTEM: STABLE\n\n");
    
    terminal_writestring("BRYNIX 64 BASIC V1.0\n");
    terminal_writestring("TYPE 'HELP' FOR COMMANDS\n\n");
    
    terminal_writestring("READY.\n>");
    
    // NOW we're ready for cursor
    cursor_ready = 1;
    
    // Command processing loop
    while (1) {
        uint8_t status = inb(0x64);
        if (status & 0x01) {
            uint8_t scancode = inb(0x60);
            
            // Ignore key releases (bit 7 set)
            if (!(scancode & 0x80)) {
                char ch = scancode_to_char(scancode);
                
                if (ch == '\n') {
                    input_buffer[input_length] = '\0';
                    process_command(input_buffer);
                    input_length = 0;
                } else if (ch == '\b') {
                    if (input_length > 0) {
                        input_length--;
                        if (terminal_column > 0) {
                            terminal_column--;
                        } else if (terminal_row > 0) {
                            terminal_row--;
                            terminal_column = VGA_WIDTH - 1;
                        }
                        terminal_buffer[terminal_row * VGA_WIDTH + terminal_column] = vga_entry(' ', terminal_color);
                    }
                } else if (ch >= 32 && ch <= 126) {
                    if (input_length < INPUT_BUFFER_SIZE - 1) {
                        input_buffer[input_length++] = ch;
                        terminal_putchar(ch);
                    }
                }
            }
        }
        
        // Simple cursor blink at current terminal position
        static uint64_t counter = 0;
        static uint8_t cursor_visible = 1;
        counter++;
        
        if (cursor_ready && counter % 100000 == 0) {
            size_t cursor_pos = terminal_row * VGA_WIDTH + terminal_column;
            
            if (cursor_visible) {
                terminal_buffer[cursor_pos] = vga_entry('_', terminal_color);
                cursor_visible = 0;
            } else {
                terminal_buffer[cursor_pos] = vga_entry(' ', terminal_color);
                cursor_visible = 1;
            }
        }
        
        for (volatile int i = 0; i < 1000; i++);
    }
}
