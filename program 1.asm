; ==========================================================
; CP4UA53O - Computer Architecture (Element 2)
; Program 1: Least Common Multiple (LCM) of two constants
; Toolchain target: x86 (Win32) MASM in Visual Studio
; Output: LCM as process exit code for zero case, 1 for overflow & other value (and optional console print)
; ==========================================================

.386                                ; enable 80386 instruction set
.model flat, stdcall                ; use flat memory model and stdcall calling convention
option casemap:none                 ; disable automatic case mapping (symbols are case-sensitive)
.stack 4096                         ; reserve 4096 bytes for stack

includelib kernel32.lib             ; link kernel32.lib for Win32 APIs

ExitProcess   PROTO stdcall, dwExitCode:DWORD      ; prototype for ExitProcess Parameters: (handle, pointer-to-buffer, number-of-characters-to-write, pointer-to-DWORD-to-receive-number-written, reserved (NULL)).
GetStdHandle  PROTO stdcall, nStdHandle:DWORD      ; prototype for GetStdHandle 
WriteConsoleA PROTO stdcall, hConsoleOutput:DWORD, \
                               lpBuffer:PTR BYTE, \
                               nNumberOfCharsToWrite:DWORD, \
                               lpNumberOfCharsWritten:PTR DWORD, \
                               lpReserved:DWORD                 ; prototype for WriteConsoleA

STD_OUTPUT_HANDLE equ -11            ; constant value for standard output handle

.data
    num1    dd 48                    ; first input value (unsigned 32 bit)
    num2    dd 180                   ; second input value (unsigned 32 bit)

    outLabel db "LCM = ",0           ; output label string (null terminated)
    errMsg   db "ERROR: LCM overflow (>= 2^32)",13,10,0 ; overflow error message string (13 (CR) and 10 (LF) + null terminator)
    nl       db 13,10,0              ; New line characters 13 (CR) and 10 (LF) + null terminator

    buf     db 12 dup(0)             ; buffer for decimal conversion (11 digits + null terminator) buffer size 12 bytes
    charsW  dd 0                     ; receives character count from WriteConsoleA

.code

; ----------------------------------------------------------
; PrintZStr
; Prints a zero terminated string to the console
; IN: EDX = address of string
; ----------------------------------------------------------
PrintZStr PROC
    pushad                          ; save all general purpose registers on stack

    invoke GetStdHandle, STD_OUTPUT_HANDLE ; get handle for standard output
    mov ebx, eax                    ; store console handle in EBX for WriteConsoleA

    xor ecx, ecx                    ; clear ECX to use as length counter
len_loop:
    cmp byte ptr [edx+ecx], 0       ; Scan from [EDX] to find null terminator, EDX= string length
    je  len_done                    ; jump if null terminator found
    inc ecx                         ; increment length counter until null terminator found
    jmp len_loop                    ; repeat length scan loop

len_done:
    invoke WriteConsoleA, ebx, edx, ecx, ADDR charsW, 0 ; write string to console string (ECX chars) to console ebx=handle, edx=ptr, ecx=len 

    popad                           ; restore all registers from stack
    ret                             ; return to caller
PrintZStr ENDP

; ----------------------------------------------------------
; U32ToDecStr
; Converts unsigned 32 bit value to decimal string
; IN : EAX = unsigned value
; OUT: EDX = pointer to string, ECX = length
; ----------------------------------------------------------
U32ToDecStr PROC
    push ebx                        ; save EBX register on stack ebx will be used as divisor
    push esi                        ; save ESI register on stack esi will hold the value being converted
    push edi                        ; save EDI register on stack edi will point to buffer

    lea edi, buf                    ; load address of buffer EDI = &buf[0]
    add edi, 11                     ; move to end of buffer EDI -> buf + 11 (reserve last byte for null) buf[11]
    mov byte ptr [edi], 0           ; write null terminator at end of buffer
    dec edi                         ; move to last digit position buf[10]

    mov ebx, 10                     ; set divisor to base 10 for decimal conversion
    mov esi, eax                    ; copy value to ESI for processing

    test esi, esi                   ; check if value equals zero
    jnz convert_loop                ; jump if value is not zero, enter conversion loop

    mov byte ptr [edi], '0'         ; store ASCII zero if value is zero
    mov edx, edi                    ; set pointer to digit in EDX
    mov ecx, 1                      ; set length to one
    jmp convert_done                ; skip conversion loop

convert_loop:
    mov eax, esi                    ; load current value into EAX for division
    xor edx, edx                    ; clear EDX before DIVISION (EDX:EAX is dividend)
    div ebx                         ; unsigned divide: quotient->EAX, remainder->EDX
    add dl, '0'                     ; convert remainder to ASCII digit
    mov [edi], dl                   ; store digit in buffer
    dec edi                         ; move left in buffer for next digit
    mov esi, eax                    ; update quotient for next iteration
    test esi, esi                   ; test if quotient is zero so we can stop
    jnz convert_loop                ; continue if not zero

    inc edi                         ; adjust pointer to first digit
    mov edx, edi                    ; set output pointer to start of string
    lea eax, buf                    ; load buffer base address
    add eax, 11                     ; compute buffer end EAX = buffer + 11
    sub eax, edx                    ; calculate string length EAX = (buf + 11) - EDX
    mov ecx, eax                    ; store length in ECX = length

convert_done:
    pop edi                         ; restore EDI register from stack
    pop esi                         ; restore ESI register from stack
    pop ebx                         ; restore EBX register from stack
    ret                             ; return to caller
U32ToDecStr ENDP

; ----------------------------------------------------------
; PrintU32
; Prints unsigned 32 bit integer
; IN : EAX = value
; ----------------------------------------------------------
PrintU32 PROC
    push ebx                        ; save EBX to stack (used for console handle)
    push eax                        ; save EAX value to stack (will be used in U32ToDecStr)
    invoke GetStdHandle, STD_OUTPUT_HANDLE ; get console handle standard output
    mov ebx, eax                    ; store console handle in EBX for WriteConsoleA
    pop eax                         ; restore EAX value from stack
    call U32ToDecStr                ; convert integer to string (EDX=ptr, ECX=len)
    invoke WriteConsoleA, ebx, edx, ecx, ADDR charsW, 0 ; print number to console ebx=handle, edx=ptr, ecx=len
    pop ebx                         ; restore EBX from stack
    ret                             ; return to caller
PrintU32 ENDP

; ----------------------------------------------------------
; main
; Computes GCD safely and then LCM = (num1 / gcd) * num2.
; Guards prevent any DIV by zero; if either input is zero, LCM = 0.
; Exits with LCM as exit code, or 1 for overflow, or 0 for zero case.
; ----------------------------------------------------------
main PROC
    mov eax, [num1]                 ; load first input eax = num1
    mov ebx, [num2]                 ; load second input ebx = num2

    test eax, eax                   ; test if num1 equals zero
    jz zero_case                    ; jump if zero
    test ebx, ebx                   ; test if num2 equals zero
    jz zero_case                    ; jump if zero

gcd_loop:
    xor edx, edx                    ; clear remainder register
    div ebx                         ; divide EAX by EBX
    mov eax, ebx                    ; move divisor to EAX
    mov ebx, edx                    ; move remainder to EBX
    test ebx, ebx                   ; test if remainder is zero
    jnz gcd_loop                    ; repeat loop if not zero

    mov ecx, eax                    ; store GCD in ECX

    mov eax, [num1]                 ; reload num1
    xor edx, edx                    ; clear high dividend
    div ecx                         ; compute num1 divided by GCD

    mov ebx, [num2]                 ; load num2
    mul ebx                         ; multiply, result in EDX:EAX

    test edx, edx                   ; check high 32 bits for overflow
    jnz overflow_case               ; jump if overflow detected

    mov ebx, eax                    ; store LCM result

    lea edx, outLabel               ; load label address
    call PrintZStr                  ; print label
    mov eax, ebx                    ; load LCM value
    call PrintU32                   ; print LCM value
    lea edx, nl                     ; load newline address
    call PrintZStr                  ; print newline

    invoke ExitProcess, ebx          ; exit with LCM as exit code

overflow_case:
    lea edx, errMsg                 ; load error message address
    call PrintZStr                  ; print overflow message
    invoke ExitProcess, 1            ; exit with error code 1

zero_case:
    lea edx, outLabel               ; load label address
    call PrintZStr                  ; print label
    xor eax, eax                    ; set value to zero
    call PrintU32                   ; print zero
    lea edx, nl                     ; load newline
    call PrintZStr                  ; print newline
    invoke ExitProcess, 0            ; exit with code 0

main ENDP
END main
