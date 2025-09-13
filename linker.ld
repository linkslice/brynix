ENTRY(_start)

SECTIONS
{
    . = 0x100000;
    
    /* Multiboot header MUST be first and within first 8KB */
    .multiboot : {
        . = ALIGN(4);
        *(.multiboot)
        . = ALIGN(4);
    }
    
    /* Everything else follows */
    .text : {
        *(.text)
    }
    
    .rodata : {
        *(.rodata)
    }
    
    .data : {
        *(.data)
    }
    
    .bss : {
        *(.bss)
        *(COMMON)
    }
}

