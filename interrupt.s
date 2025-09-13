# interrupt.s - Simple default interrupt handler
.section .text
.global default_handler

default_handler:
    # Just return from any interrupt
    push %rax
    mov $0x20, %al
    out %al, $0x20     # Send EOI to PIC
    pop %rax
    iretq

