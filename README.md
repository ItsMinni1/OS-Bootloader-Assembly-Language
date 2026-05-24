# 🚀 3-Stage x86_64 Bootloader

This project is a minimalist, multi-stage bootloader written in x86 Assembly (NASM). It demonstrates the foundational steps required to boot an x86 processor from a cold reset up to 64-bit Long Mode, transitioning through Real Mode and Protected Mode along the way.

---

## 🏃‍♂️ Execution Flow & Features

The bootloader transitions through three distinct CPU modes:

### 1️⃣ Stage 1: 16-bit Real Mode (`0x7C00`)
* **Initializes CPU registers** and sets up a temporary system stack.
* **Leverages BIOS Interrupt `INT 0x13`** to load an additional 5 sectors (Stage 2) from the boot drive into RAM address `0x7E00`.
* **Enables the A20 Line** using the Fast A20 Gate method (port `0x92`) to break past the 1MB memory barrier.
* **Loads a basic 32-bit Global Descriptor Table (GDT)** and toggles `CR0.PE` to switch into Protected Mode.

### 2️⃣ Stage 2: 32-bit Protected Mode (`0x7E00`)
* **Clears the instruction pipeline** using a far jump and updates data segments.
* **Prints a visual 'P'** directly to VGA Video Memory (`0xB8000`) to confirm a successful mode transition.
* **Sets up 4-level Identity Paging** (PML4, PDPT, and a 2MB Huge Page) mapped at memory location `0x1000`.
* **Sets the `EFER.LME` (Long Mode Enable) MSR** and enables Paging (`CR0.PG`).
* **Loads the 64-bit GDT** and jumps into Long Mode.

### 3️⃣ Stage 3: 64-bit Long Mode
* **Nullifies data segments** (as required by x86_64 architecture).
* **Writes "OK" onto the screen** using a white text/green background attribute.
* **Streams "OK\n" sequentially** to the first Serial COM port (`0x3F8`) for debugging.
* **Halts execution** (`hlt`).

---

## 🗺️ Memory Map Layout

The bootloader configures and utilizes physical memory according to the following layout:

| Memory Address | Size | Description |
| :--- | :--- | :--- |
| `0x1000` | 4 KB | PML4 (Page Map Level 4 Table) |
| `0x2000` | 4 KB | PDPT (Page Directory Pointer Table) |
| `0x3000` | 4 KB | PD (Page Directory - Maps a 2MB Huge Page) |
| `0x7C00` | 512 B | Stage 1 (MBR Boot Sector Execution Address) |
| `0x7E00` | 2.5 KB | Stage 2 & Stage 3 Execution Area (Loaded from Disk) |
| `0x90000` | — | 32-bit Protected Mode Stack Base |
| `0xB8000` | 32 KB | Text Mode VGA Video Memory Buffer |

---

## 🛠️ Prerequisites

To compile and emulate this bootloader, you will need an assembler (NASM) and an emulator (QEMU).

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install nasm qemu-system-x86
```

### macOS (via Homebrew)
```bash
brew install nasm qemu
```

### Windows
Download the binaries for [NASM](https://www.nasm.us/) and [QEMU](https://www.qemu.org/) and add them to your system's environmental `PATH`.

---

## ⚙️ Compilation & Running

Use the repository `Makefile` to assemble the source and generate the raw boot binary.

### 1. Build the Bootloader
Run the default Make target to compile `boot.asm` into `boot.bin`:
```bash
make
```

### 2. Clean Build Artifacts
Remove the generated output file with:
```bash
make clean
```

### 3. Run with QEMU
Boot the generated raw binary in QEMU:
```bash
qemu-system-x86_64 -drive format=raw,file=boot.bin
```

### 4. Run with Serial Debugging (Recommended)
Because the bootloader writes status output to the serial port (`0x3F8`), you can redirect it to your terminal:
```bash
qemu-system-x86_64 -drive format=raw,file=boot.bin -serial stdio
```

> [!NOTE]
> This project currently produces a raw binary file named `boot.bin`, not `boot.img`.

---

## 🔍 Code Architecture Highlights

* **Note on Paging:** The implementation implements Identity Paging for the lowest 2 Megabytes of system memory. It leverages CR4's Physical Address Extension (PAE) bit and constructs a 2MB Page frame directly inside the Page Directory (PD) entry by enabling the Huge Page bit (bit 7), bypassing the necessity of a fine-grained Level 1 Page Table (PT).
* **The Magic Number:** The first sector relies strictly on the `0xAA55` word signature at offset 510 to trick the system BIOS into recognizing the drive as actively bootable code.