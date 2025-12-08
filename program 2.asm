; ==========================================================
; CP4UA53O - Computer Architecture (Element 2)
; Program 2: Sum all ODD numbers in a given range (inclusive)
; Toolchain target: x86 (Win32) MASM in Visual Studio 2022/2026
; Output: sum as process exit code (+ optional console print)
; ==========================================================

.386
.model flat, stdcall
option casemap:none

includelib kernel32.lib

ExitProcess   PROTO stdcall, dwExitCode:DWORD
GetStdHandle  PROTO stdcall, nStdHandle:DWORD
WriteConsoleA PROTO stdcall, hConsoleOutput:DWORD, lpBuffer:PTR BYTE, nNumberOfCharsToWrite:DWORD, lpNumberOfCharsWritten:PTR DWORD, lpReserved:DWORD

STD_OUTPUT_HANDLE equ -11

.data
    ; ---- Edit these bounds to match your required range ----
    rangeStart  dd 1
    rangeEnd    dd 100

    nl          db 13,10            ; CRLF (fixed length = 2)
    outLabel    db "Odd-sum = ",0

    ; buffer for printing unsigned 32-bit integer (max 10 digits) + null
    buf         db 12 dup(0)
    charsW      dd 0

.code

; ----------------------------------------------------------
; PrintZStr
;   Writes a null-terminated string to the console.
;   IN:  EDX = address of zero-terminated string
; ----------------------------------------------------------
PrintZStr PROC
    pushad
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov ebx, eax

    mov ecx, 0
len_loop:
    cmp byte ptr [edx+ecx], 0
    je  len_done
    inc ecx
    jmp len_loop
len_done:
    invoke WriteConsoleA, ebx, edx, ecx, ADDR charsW, 0
    popad
    ret
PrintZStr ENDP

; ----------------------------------------------------------
; PrintNL
;   Writes CRLF using fixed length (2 characters)
; ----------------------------------------------------------
PrintNL PROC
    pushad
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov ebx, eax
    invoke WriteConsoleA, ebx, ADDR nl, 2, ADDR charsW, 0
    popad
    ret
PrintNL ENDP

; ----------------------------------------------------------
; U32ToDecStr
;   Converts unsigned EAX -> decimal string in buf.
;   OUT: EDX = pointer to first char, ECX = length (no null)
; ----------------------------------------------------------
U32ToDecStr PROC
    push ebx
    push esi
    push edi

    lea edi, buf
    add edi, 11
    mov byte ptr [edi], 0           ; null terminator (not counted)
    dec edi

    mov ebx, 10
    mov esi, eax

    test esi, esi
    jnz  conv_loop

    mov byte ptr [edi], '0'
    mov edx, edi
    mov ecx, 1
    jmp  conv_done

conv_loop:
    mov eax, esi
    xor edx, edx
    div ebx                         ; EAX=quot, EDX=rem
    add dl, '0'
    mov byte ptr [edi], dl
    dec edi
    mov esi, eax
    test esi, esi
    jnz  conv_loop

    inc edi                         ; first digit
    mov edx, edi

    lea eax, buf
    add eax, 11                     ; terminator position
    sub eax, edx
    mov ecx, eax                    ; length

conv_done:
    pop edi
    pop esi
    pop ebx
    ret
U32ToDecStr ENDP

; ----------------------------------------------------------
; PrintU32
;   Prints unsigned integer in EAX
; ----------------------------------------------------------
PrintU32 PROC
    push ebx
    call U32ToDecStr                ; returns EDX ptr, ECX len
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov ebx, eax
    invoke WriteConsoleA, ebx, edx, ecx, ADDR charsW, 0
    pop ebx
    ret
PrintU32 ENDP

main PROC
    mov esi, rangeStart             ; i
    mov edi, rangeEnd               ; end
    xor ebx, ebx                    ; sum = 0

sum_loop:
    cmp esi, edi
    jg  sum_done

    test esi, 1                     ; odd? (LSB=1)
    jz   not_odd 				  ; if even, skip addition
    add ebx, esi 				 ; sum += i

not_odd: 
    inc esi 					; i++
    jmp sum_loop 

sum_done:
    ; Optional print (extra marks)
    lea edx, outLabel 
    call PrintZStr
    mov eax, ebx
    call PrintU32
    call PrintNL

    ; Required: output as exit code
    invoke ExitProcess, ebx
main ENDP


END main
