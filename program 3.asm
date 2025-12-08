; ==========================================================
; CP4UA53O - Computer Architecture (Element 2)
; Program 3: Multiply your student number by 3 and print result
; Student ID: 34125387  (stored as integer, not a string)
; Toolchain target: x86 (Win32) MASM in Visual Studio 2022/2026
; Requirement: integer -> ASCII conversion must be your own code
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
    studentID   dd 34125387
    multiplier  dd 3

    nl          db 13,10                 ; CRLF (2 bytes)
    outLabel    db "StudentID * 3 = ",0

    buf         db 12 dup(0)             ; 10 digits max + null + spare
    charsW      dd 0

.code

; ----------------------------------------------------------
; PrintZStr: print null-terminated string (EDX)
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
; PrintNL: print CRLF using fixed length = 2
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
; Converts unsigned EAX -> decimal string in buf.
; OUT: EDX = pointer to first digit, ECX = length (no null)
; ----------------------------------------------------------
U32ToDecStr PROC
    push ebx
    push esi
    push edi

    lea edi, buf
    add edi, 11
    mov byte ptr [edi], 0              ; null terminator (not counted)
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
    div ebx                            ; EAX=quot, EDX=rem
    add dl, '0'
    mov byte ptr [edi], dl
    dec edi
    mov esi, eax
    test esi, esi
    jnz  conv_loop

    inc edi                            ; first digit
    mov edx, edi

    lea eax, buf
    add eax, 11                        ; terminator position
    sub eax, edx
    mov ecx, eax                       ; length

conv_done:
    pop edi
    pop esi
    pop ebx
    ret
U32ToDecStr ENDP

; ----------------------------------------------------------
; PrintU32: prints unsigned integer in EAX
; ----------------------------------------------------------
PrintU32 PROC
    push ebx
    call U32ToDecStr                   ; returns EDX ptr, ECX len
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov ebx, eax
    invoke WriteConsoleA, ebx, edx, ecx, ADDR charsW, 0
    pop ebx
    ret
PrintU32 ENDP

main PROC
    mov eax, studentID
    mul multiplier                     ; EDX:EAX = studentID * 3
    mov ebx, eax                       ; result (fits 32-bit here)

    lea edx, outLabel
    call PrintZStr
    mov eax, ebx
    call PrintU32
    call PrintNL

    invoke ExitProcess, ebx
main ENDP

END main
