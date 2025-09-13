# boot.s - Minimal amd64 kernel boot stub
.section .multiboot
.align 4
multiboot_header:
    .long 0x1BADB002        # Magic number
    .long 0x00000000        # Flags (no special requirements)
    .long -(0x1BADB002 + 0x00000000)  # Checksum

.section .text
.global _start
.code32

_start:
    # Disable interrupts
    cli
    
    # Set up stack
    movl $stack_top, %esp
    
    # Set up basic GDT for protected mode
    lgdt gdt_descriptor
    
    # Reload code segment
    ljmp $0x08, $reload_cs

reload_cs:
    # Set up data segments
    movw $0x10, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    movw %ax, %ss
    
    # Check for long mode support
    call check_long_mode
    testl %eax, %eax
    jz hang
    
    # Set up paging for long mode
    call setup_paging
    
    # Enable long mode
    call enable_long_mode
    
    # Jump to 64-bit code
    ljmp $0x18, $long_mode_start

check_long_mode:
    # Check CPUID support
    pushfl
    popl %eax
    movl %eax, %ecx
    xorl $0x200000, %eax
    pushl %eax
    popfl
    pushfl
    popl %eax
    xorl %ecx, %eax
    jz no_long_mode
    
    # Check for extended functions
    movl $0x80000000, %eax
    cpuid
    cmpl $0x80000001, %eax
    jb no_long_mode
    
    # Check long mode bit
    movl $0x80000001, %eax
    cpuid
    testl $0x20000000, %edx
    jz no_long_mode
    
    movl $1, %eax
    ret

no_long_mode:
    movl $0, %eax
    ret

setup_paging:
    # Clear page tables
    movl $pml4, %edi
    xorl %eax, %eax
    movl $1024, %ecx
    rep stosl
    
    movl $pdpt, %edi
    xorl %eax, %eax
    movl $1024, %ecx
    rep stosl
    
    movl $pdt, %edi
    xorl %eax, %eax
    movl $1024, %ecx
    rep stosl
    
    # Set up PML4
    movl $pdpt, %eax
    orl $0x3, %eax
    movl %eax, pml4
    
    # Set up PDPT
    movl $pdt, %eax
    orl $0x3, %eax
    movl %eax, pdpt
    
    # Set up PDT (identity map first 2MB)
    movl $0x83, %eax
    movl %eax, pdt
    
    ret

enable_long_mode:
    # Load CR3 with PML4
    movl $pml4, %eax
    movl %eax, %cr3
    
    # Enable PAE
    movl %cr4, %eax
    orl $0x20, %eax
    movl %eax, %cr4
    
    # Enable long mode
    movl $0xC0000080, %ecx
    rdmsr
    orl $0x100, %eax
    wrmsr
    
    # Enable paging
    movl %cr0, %eax
    orl $0x80000000, %eax
    movl %eax, %cr0
    
    ret

.code64
long_mode_start:
    # Set up 64-bit segments
    movw $0x20, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    movw %ax, %ss
    
    # Call kernel main
    call kernel_main
    
    # If kernel_main ever returns (it shouldn't), halt forever
    cli
hang:
    hlt
    jmp hang

# GDT for protected mode and long mode
.align 16
gdt_start:
    # Null descriptor
    .quad 0
    
    # 32-bit code segment
    .word 0xFFFF    # Limit 0-15
    .word 0x0000    # Base 0-15
    .byte 0x00      # Base 16-23
    .byte 0x9A      # Access byte
    .byte 0xCF      # Flags + Limit 16-19
    .byte 0x00      # Base 24-31
    
    # 32-bit data segment
    .word 0xFFFF
    .word 0x0000
    .byte 0x00
    .byte 0x92
    .byte 0xCF
    .byte 0x00
    
    # 64-bit code segment
    .word 0x0000
    .word 0x0000
    .byte 0x00
    .byte 0x9A
    .byte 0xAF
    .byte 0x00
    
    # 64-bit data segment
    .word 0x0000
    .word 0x0000
    .byte 0x00
    .byte 0x92
    .byte 0x00
    .byte 0x00

gdt_descriptor:
    .word gdt_descriptor - gdt_start - 1
    .long gdt_start

.section .bss
.align 4096
pml4:
    .skip 4096
pdpt:
    .skip 4096
pdt:
    .skip 4096

.align 16
stack_bottom:
    .skip 16384
stack_top:
