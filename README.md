To start, you need NASM and QEMU
Run this on your terminal: sudo apt install nasm && sudo apt install qemu-system qemu-utils libvirt-daemon-system libvirt-clients bridge-utils virt-manager
Go to your project directory and write "make all"
This should make a "boot.bin" file.
Then write "qemu-system-x86_64 ./boot.bin"
You should see a small window titled "QEMU" pop up!
It will say OK in the top left corner. 
Congrats! It works :D
