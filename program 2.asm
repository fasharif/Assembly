; ==========================================================
; CP4UA53O - Computer Architecture (Element 2)
; Program 2: Sum all ODD numbers in a given range (inclusive)
; Toolchain target: x86 (Win32) MASM in Visual Studio 2022/2026
; Output: sum as process exit code (+ optional console print)
; covering full 32-bit unsigned range(zero to overflow(2^32-1)) 
; ==========================================================

.386                         ; enable 80386+ instruction set (32-bit registers)
.model flat, stdcall         ; flat memory model for Win32, use stdcall calling convention
option casemap:none          ; disable automatic case-insensitive symbol mapping (case-sensitive)
.stack 4096                  ; reserve 4096 bytes of stack space 

includelib kernel32.lib      ; link against kernel32.lib to use Win32 API functions

ExitProcess   PROTO stdcall, dwExitCode:DWORD
                             ; prototype for ExitProcess (stdcall) which terminates the process
GetStdHandle  PROTO stdcall, nStdHandle:DWORD
                             ; prototype for GetStdHandle which returns a standard device handle
WriteConsoleA PROTO stdcall, hConsoleOutput:DWORD, lpBuffer:PTR BYTE, nNumberOfCharsToWrite:DWORD, lpNumberOfCharsWritten:PTR DWORD, lpReserved:DWORD
                             ; prototype for WriteConsoleA: (handle, buffer ptr, num chars, ptr to chars-written, reserved)

STD_OUTPUT_HANDLE equ -11    ; constant for GetStdHandle to request standard output handle

.data
    ; ---- Edit these bounds to match your required range ----
    rangeStart  dd 0        ; starting value of the range (inclusive)
    rangeEnd    dd 100      ; ending value of the range (inclusive)

    nl          db 13,10    ; CR(13) LF(10) pair for newline (not null-terminated)
    outLabel    db "Odd-sum = ",0 ; null-terminated label string printed before the sum

    ; buffer for printing unsigned 32-bit integer (up to 11 digits + terminator)
    buf         db 12 dup(0) ; 12-byte buffer: supports up to 11-digit decimal + null terminator
    charsW      dd 0         ; DWORD used by WriteConsoleA to receive the number of characters written

.code

; ----------------------------------------------------------
; PrintZStr
;   Writes a null-terminated string to the console using WriteConsoleA
;   IN:  EDX = address of null-terminated string
; ----------------------------------------------------------
PrintZStr PROC
    pushad                  ; save all general-purpose registers (EAX,ECX,EDX,EBX,ESP,EBP,ESI,EDI saved by pushad)
    invoke GetStdHandle, STD_OUTPUT_HANDLE ; call GetStdHandle(STD_OUTPUT_HANDLE) to get console handle
    mov ebx, eax            ; store returned console handle in EBX for subsequent WriteConsoleA call

    mov ecx, 0              ; initialize length counter (ECX = 0)
len_loop:
    cmp byte ptr [edx+ecx], 0 ; compare byte at EDX+ECX with 0 to test for null terminator
    je  len_done            ; jump if null terminator found (string length determined)
    inc ecx                 ; increment length counter to move to next character
    jmp len_loop            ; repeat loop until null terminator is reached
len_done:
    invoke WriteConsoleA, ebx, edx, ecx, ADDR charsW, 0 ; write ECX characters from [EDX] to console
    popad                   ; restore registers saved by pushad
    ret                     ; return to caller
PrintZStr ENDP

; ----------------------------------------------------------
; PrintNL
;   Writes a fixed CRLF sequence to the console (2 characters)
; ----------------------------------------------------------
PrintNL PROC
    pushad                  ; save registers
    invoke GetStdHandle, STD_OUTPUT_HANDLE ; get console handle
    mov ebx, eax            ; keep handle in EBX
    invoke WriteConsoleA, ebx, ADDR nl, 2, ADDR charsW, 0 ; write two characters at address nl (CR and LF)
    popad                   ; restore registers
    ret                     ; return
PrintNL ENDP

; ----------------------------------------------------------
; U32ToDecStr
;   Convert unsigned 32-bit integer in EAX to decimal ASCII string in 'buf'
;   OUT: EDX = pointer to first digit, ECX = digit count (excludes null)
; ----------------------------------------------------------
U32ToDecStr PROC
    push ebx                ; preserve EBX
    push esi                ; preserve ESI
    push edi                ; preserve EDI

    lea edi, buf            ; EDI = address of buffer start
    add edi, 11             ; EDI -> buf + 11 (reserve last byte for null)
    mov byte ptr [edi], 0   ; place null terminator at buffer end
    dec edi                 ; move EDI to position for least-significant digit

    mov ebx, 10             ; EBX = 10 (decimal divisor)
    mov esi, eax            ; ESI = working copy of the value to convert

    test esi, esi           ; test if value == 0
    jnz  conv_loop          ; if non-zero, go to conversion loop

    mov byte ptr [edi], '0' ; handle zero explicitly by storing ASCII '0'
    mov edx, edi            ; EDX points to the first digit character
    mov ecx, 1              ; ECX = length 1 for "0"
    jmp  conv_done          ; skip conversion loop

conv_loop:
    mov eax, esi            ; move working value into EAX for division
    xor edx, edx            ; clear EDX (high part of dividend) before DIV
    div ebx                 ; divide EDX:EAX by EBX -> quotient in EAX, remainder in EDX
    add dl, '0'             ; convert remainder (0-9) to ASCII by adding ASCII '0'
    mov byte ptr [edi], dl  ; store ASCII digit at current buffer position
    dec edi                 ; move buffer pointer left for next digit
    mov esi, eax            ; update working value = quotient
    test esi, esi           ; check if quotient is zero now
    jnz  conv_loop          ; if not zero, continue extracting digits

    inc edi                 ; adjust EDI to point to first digit stored
    mov edx, edi            ; output pointer to first digit in EDX

    lea eax, buf            ; EAX = address of buffer start
    add eax, 11             ; EAX = address of null terminator in buffer
    sub eax, edx            ; EAX = (buf+11) - firstDigitPtr = digit count
    mov ecx, eax            ; ECX = digit count

conv_done:
    pop edi                 ; restore EDI
    pop esi                 ; restore ESI
    pop ebx                 ; restore EBX
    ret                     ; return to caller (EDX=pointer, ECX=length)
U32ToDecStr ENDP

; ----------------------------------------------------------
; PrintU32
;   Print unsigned integer found in EAX to console using U32ToDecStr + WriteConsoleA
;   IN:  EAX = unsigned integer to print
;   Uses: EDX (pointer) and ECX (length) as returned by U32ToDecStr
; ----------------------------------------------------------
PrintU32 PROC
    push ebx                ; save EBX which will hold console handle
    push eax                ; preserve EAX (value to print)
    invoke GetStdHandle, STD_OUTPUT_HANDLE ; get console handle for output
    mov ebx, eax            ; store handle in EBX for WriteConsoleA
    pop eax                 ; restore EAX (value to print)
    call U32ToDecStr        ; convert EAX to decimal string in buf (outputs EDX=ptr, ECX=len)
    invoke WriteConsoleA, ebx, edx, ecx, ADDR charsW, 0 ; write the converted digits to console
    pop ebx                 ; restore EBX from stack
    ret                     ; return to caller
PrintU32 ENDP

; ----------------------------------------------------------
; main
;   Sum all odd numbers in the inclusive range [rangeStart, rangeEnd]
;   Result is returned as the process exit code and optionally printed
; ----------------------------------------------------------
main PROC
    mov esi, rangeStart     ; ESI = loop index initialized to rangeStart
    mov edi, rangeEnd       ; EDI = end value of the range
    xor ebx, ebx            ; EBX = accumulator for sum, initialize to 0

sum_loop:
    cmp esi, edi            ; compare current index (ESI) with end (EDI)
    ja  sum_done            ; if ESI > EDI, we've processed the full range, exit loop

    test esi, 1             ; test least significant bit: sets ZF if ESI is even
    jz   not_odd            ; if zero flag set (even), skip adding
    add ebx, esi            ; ESI is odd -> add it to accumulator EBX

not_odd:
    cmp esi, edi 		    ; compare current index (ESI) with end (EDI) again
    je  sum_done 		    ; if ESI == EDI, we've reached the end, exit loop
    inc esi                 ; increment loop index (ESI++)
    jmp sum_loop            ; repeat loop

sum_done:
    ; Optional printing of result (extra-credit/diagnostic)
    lea edx, outLabel       ; EDX = address of output label string
    call PrintZStr          ; print "Odd-sum = " label
    mov eax, ebx            ; move computed sum into EAX for printing
    call PrintU32           ; print sum as unsigned integer
    call PrintNL            ; print CRLF

    ; Return result as process exit code (EBX contains the sum)
    invoke ExitProcess, ebx ; call ExitProcess(sum) to terminate program with sum as exit code
main ENDP

END main
 
