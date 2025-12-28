all:
	nasm -f bin ./boot.asm -o ./boot.bin

clean:
	rm -f ./boot.bin