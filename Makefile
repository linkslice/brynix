CC = gcc
AS = as
LD = ld
OBJCOPY = objcopy

CFLAGS = -ffreestanding -O2 -Wall -Wextra -nostdlib -m64 -mcmodel=large -mno-red-zone -mno-mmx -mno-sse -mno-sse2
ASFLAGS = --64
LDFLAGS = -T linker.ld -nostdlib

OBJECTS = boot.o kernel.o interrupt.o

all: kernel.elf

kernel.elf: $(OBJECTS)
	$(LD) $(LDFLAGS) -o kernel.elf $(OBJECTS)

boot.o: boot.s
	$(AS) $(ASFLAGS) -o boot.o boot.s

kernel.o: kernel.c
	$(CC) $(CFLAGS) -c kernel.c -o kernel.o

interrupt.o: interrupt.s
	$(AS) $(ASFLAGS) -o interrupt.o interrupt.s

iso: kernel.elf
	mkdir -p iso/boot/grub
	cp kernel.elf iso/boot/kernel.elf
	echo 'set timeout=0' > iso/boot/grub/grub.cfg
	echo 'set default=0' >> iso/boot/grub/grub.cfg
	echo 'terminal_output console' >> iso/boot/grub/grub.cfg
	echo 'set gfxmode=text' >> iso/boot/grub/grub.cfg
	echo 'set gfxpayload=text' >> iso/boot/grub/grub.cfg
	echo '' >> iso/boot/grub/grub.cfg
	echo 'menuentry "COMMANDANT 64 KERNEL" {' >> iso/boot/grub/grub.cfg
	echo '    set gfxpayload=text' >> iso/boot/grub/grub.cfg
	echo '    multiboot /boot/kernel.elf' >> iso/boot/grub/grub.cfg
	echo '}' >> iso/boot/grub/grub.cfg
	grub2-mkrescue -o kernel.iso iso/

rawimg: kernel.elf
	# Create a 16MB raw disk image
	dd if=/dev/zero of=commandant.img bs=1M count=16
	# Create partition table and format (using sfdisk)
	echo "2048,,L,*" | sfdisk commandant.img
	# Set up loop device for the image
	sudo losetup -P /dev/loop0 commandant.img || true
	# Format the partition as FAT32
	sudo mkfs.fat -F32 /dev/loop0p1
	# Mount the partition
	mkdir -p /tmp/commandant_mount
	sudo mount /dev/loop0p1 /tmp/commandant_mount
	# Install GRUB to the image
	sudo grub2-install --target=i386-pc --boot-directory=/tmp/commandant_mount/boot /dev/loop0
	# Copy our kernel
	sudo mkdir -p /tmp/commandant_mount/boot/grub
	sudo cp kernel.elf /tmp/commandant_mount/boot/kernel.elf
	# Create GRUB config
	echo 'set timeout=0' | sudo tee /tmp/commandant_mount/boot/grub/grub.cfg
	echo 'set default=0' | sudo tee -a /tmp/commandant_mount/boot/grub/grub.cfg
	echo '' | sudo tee -a /tmp/commandant_mount/boot/grub/grub.cfg
	echo 'menuentry "COMMANDANT 64 KERNEL" {' | sudo tee -a /tmp/commandant_mount/boot/grub/grub.cfg
	echo '    multiboot /boot/kernel.elf' | sudo tee -a /tmp/commandant_mount/boot/grub/grub.cfg
	echo '}' | sudo tee -a /tmp/commandant_mount/boot/grub/grub.cfg
	# Clean up
	sudo umount /tmp/commandant_mount
	sudo losetup -d /dev/loop0
	rmdir /tmp/commandant_mount
	@echo "Raw disk image created: commandant.img"
	@echo "To write to USB drive: sudo dd if=commandant.img of=/dev/sdX bs=1M status=progress"
	@echo "Replace /dev/sdX with your USB device (check with lsblk)"

clean:
	rm -f *.o kernel.elf kernel.bin kernel.iso commandant.img
	rm -rf iso/

.PHONY: all clean iso rawimg
