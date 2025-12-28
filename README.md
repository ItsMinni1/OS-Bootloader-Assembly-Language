OVERVIEW

This project contains a simple x86 bootloader written in Assembly language. It demonstrates fundamental operating system boot concepts and low-level programming techniques. The bootloader executes immediately after the BIOS transfers control and runs in 16-bit real mode directly from the boot sector.

This project is intended for educational purposes, especially for students learning operating systems, computer architecture, and Assembly language programming.

WHAT IS A BOOTLOADER

A bootloader is the first software that runs when a computer starts.

Boot sequence overview:

BIOS initializes system hardware

BIOS loads the first 512 bytes of the bootable disk into memory at address 0x7C00

CPU begins execution at that memory location

The bootloader prepares the system for the operating system

This project implements a basic stage-1 bootloader.

FEATURES

Written in x86 Assembly (NASM syntax)

Executes in 16-bit real mode

Fits entirely within a 512-byte boot sector

Uses BIOS interrupts for basic output

Includes valid boot signature (0xAA55)

Can be executed using emulators such as QEMU or Bochs

TECHNICAL DETAILS

Architecture: x86
Execution mode: 16-bit Real Mode
Boot sector size: 512 bytes
Load address: 0x7C00
Boot signature: 0xAA55
Assembler: NASM

PROJECT STRUCTURE

OS-Bootloader-Assembly-Language
|
|-- bootloader.asm Main bootloader source code
|-- README.txt Project documentation
|-- bootloader.bin Compiled boot sector binary (generated)

PREREQUISITES

Required tools:

NASM (Netwide Assembler)

QEMU or Bochs for emulation

Linux, macOS, or Windows with WSL

Example installation on Debian or Ubuntu:
sudo apt update
sudo apt install nasm qemu-system-x86

BUILD INSTRUCTIONS

Assemble the bootloader source code into a binary file:

nasm -f bin bootloader.asm -o bootloader.bin

The output file must be exactly 512 bytes in size.

RUN INSTRUCTIONS

Run the bootloader using QEMU:

qemu-system-x86_64 bootloader.bin

The emulator will boot directly into the bootloader if assembled correctly.

HOW IT WORKS

BIOS loads the boot sector into memory at 0x7C00

CPU starts executing instructions from that address

Registers are initialized by the bootloader

BIOS interrupts are used for output

Execution ends in a halt or infinite loop

The boot sector ends with the mandatory boot signature 0xAA55. Without this signature, the BIOS will not recognize the sector as bootable.

LIMITATIONS

Runs only in 16-bit real mode

No file system support

No kernel loading

No protected or long mode switching

Intended strictly for learning purposes

LEARNING OBJECTIVES

This project helps in understanding:

BIOS boot process

Real-mode execution

Boot sector layout

Assembly language fundamentals

Bare-metal programming concepts

CONTRIBUTING

Contributions are welcome.

LICENSE

This project is open-source.
