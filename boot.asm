[BITS 16]
[ORG 0x7C00]

start:
    cli
    mov [boot_drive], dl

    ; Setup stack
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Print "Booting..."
    mov si, msg_booting
    call print_string_16

    ; Load Stage 2 (rest of the code) from disk
    mov bx, 0x7E00      ; Destination address
    mov ah, 0x02        ; Read sectors
    mov al, 5           ; Number of sectors to read
    mov ch, 0           ; Cylinder
    mov dh, 0           ; Head
    mov cl, 2           ; Sector (starts at 2)
    mov dl, [boot_drive]        ; use the boot drive number saved at start
    int 0x13
    jc disk_error

    ; Switch to Protected Mode (32-bit)
    
    ; 1. Enable A20 Line (Fast A20 method)
    in al, 0x92
    or al, 2
    out 0x92, al

    ; 2. Load GDT
    lgdt [gdt_descriptor]

    ; 3. Enable Protected Mode in CR0
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; 4. Far jump to 32-bit code to flush pipeline
    jmp CODE_SEG:init_pm

disk_error:
    mov si, msg_error
    call print_string_16
    hlt

print_string_16:
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

msg_booting db 'Booting x64 OS...', 13, 10, 0
msg_error db 'Disk Read Error!', 0
boot_drive db 0

; GDT Routine
gdt_start:
    dq 0x0 ; Null Descriptor

gdt_code: ; Code Segment Descriptor (Base=0, Limit=4GB, Access=0x9A, Flags=0xC)
    dw 0xFFFF    ; Limit (bits 0-15)
    dw 0x0000    ; Base (bits 0-15)
    db 0x00      ; Base (bits 16-23)
    db 10011010b ; Access byte (Present, Ring 0, Code, Exec/Read, Accessed)
    db 11001111b ; Flags (4KB Granularity, 32-bit) + Limit (bits 16-19)
    db 0x00      ; Base (bits 24-31)

gdt_data: ; Data Segment Descriptor (Base=0, Limit=4GB, Access=0x92, Flags=0xC)
    dw 0xFFFF    ; Limit
    dw 0x0000    ; Base
    db 0x00      ; Base
    db 10010010b ; Access byte (Present, Ring 0, Data, Read/Write)
    db 11001111b ; Flags
    db 0x00      ; Base

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; Size
    dd gdt_start               ; Base address

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; Padding to 512 bytes (MBR size)
times 510-($-$$) db 0
dw 0xAA55

; STAGE 2: 32-bit Protected Mode and Switch to 64-bit Long mode

[BITS 32]

init_pm:
    ; Update segment registers
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000
    mov esp, ebp

    ; Print "Protected Mode" (direct to video memory)
    mov byte [0xb8000], 'P'
    mov byte [0xb8001], 0x0F ; White on Black

    call setup_long_mode
    
    ; Load 64-bit GDT
    lgdt [gdt64_descriptor]

    jmp CODE_SEG_64:init_lm

setup_long_mode:
    ; 1. Check if CPU supports Long Mode (CPUID)
    ; (Skipping detailed check for brevity, assuming x64 QEMU)

    ; 2. Setup Identity Paging (Map first 2MB)
    ; We will use 0x1000 for Page Tables.
    ; Memory Layout:
    ; 0x1000: PML4 (Page Map Level 4)
    ; 0x2000: PDPT (Page Directory Pointer Table)
    ; 0x3000: PD   (Page Directory)
    ; 0x4000: PT   (Page Table) 

    ; Zero out memory for page tables (4096 bytes * 3)
    mov edi, 0x1000
    xor eax, eax
    mov ecx, 1024*3 ; 3 tables * 1024 dwords
    rep stosd

    ; Link PML4 to PDPT
    mov edi, 0x1000
    mov eax, 0x2000
    or eax, 3       ; Present + Write
    mov [edi], eax

    ; Link PDPT to PD
    mov edi, 0x2000
    mov eax, 0x3000
    or eax, 3       ; Present + Write
    mov [edi], eax

    ; Link PD to Physical Memory
    mov edi, 0x3000
    mov eax, 0x0000 ; Start at physical 0
    or eax, 0x83    ; Present + Write + Huge Page (2MB)
    mov [edi], eax

    ; 3. Enable PAE 
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; 4. Load CR3 with PML4 base address
    mov eax, 0x1000
    mov cr3, eax

    ; 5. Set EFER.LME 
    mov ecx, 0xC0000080 ; EFER MSR
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; 6. Enable Paging in CR0
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ret

; 64-bit GDT
gdt64_start:
    dq 0x0 ; Null Descriptor
gdt64_code:
    dd 0x00000000
    dd 0x00209800 ; Code Segment: Accessed, Code, Conforming, Readable | Long Mode, Present, Ring 0
gdt64_data:
    dd 0x00000000 
    dd 0x00009200 ; Data Segment
gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64_start - 1
    dd gdt64_start ; 32-bit Base for LGDT in 32-bit mode

CODE_SEG_64 equ gdt64_code - gdt64_start

; STAGE 3: 64-bit Long mode

[BITS 64]

init_lm:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov rax, 0x2f4b2f4f ; "OK" in white on green
    mov [0xb8000], rax

    mov dx, 0x3f8
    mov al, 'O'
    out dx, al
    mov al, 'K'
    out dx, al
    mov al, 0x0a ; newline
    out dx, al

    hlt

; Padding to ensure we have enough sectors
times 3072-($-$$) db 0