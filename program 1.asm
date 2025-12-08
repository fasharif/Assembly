; ==========================================================
; CP4UA53O - Computer Architecture (Element 2)
; Program 1: Least Common Multiple (LCM) of two constants
; Student ID: 34125387
; Toolchain target: x86 (Win32) MASM in Visual Studio 2022/2026
; Output: LCM as process exit code (+ optional console print)
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
    ; ---- Change these two values to whatever you were asked to use ----
    num1        dd 48
    num2        dd 180

    nl          db 13,10,0 			  ; newline
    outLabel    db "LCM = ",0         ; output label

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
    mov ebx, eax                    ; handle

    ; find string length
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
; U32ToDecStr
;   Converts unsigned EAX -> decimal string in buf.
;   OUT: EDX = pointer to first char, ECX = length (no null)
; ----------------------------------------------------------
U32ToDecStr PROC
    push ebx
    push esi
    push edi

    ; Build the string from the end of buf backwards
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
    ; -------- GCD via Euclidean algorithm --------
    mov eax, num1                   ; a
    mov ebx, num2                   ; b

gcd_loop:
    cmp ebx, 0
    je  gcd_done
    mov ecx, ebx                    ; t = b
    xor edx, edx
    div ebx                         ; a / b -> rem in EDX
    mov ebx, edx                    ; b = a % b
    mov eax, ecx                    ; a = t
    jmp gcd_loop

gcd_done:
    ; EAX = gcd
    mov ecx, eax                    ; gcd -> ECX

    ; -------- LCM = (num1 / gcd) * num2 --------
    mov eax, num1
    xor edx, edx
    div ecx                         ; EAX = num1/gcd
    mul num2                        ; EDX:EAX = (num1/gcd)*num2
    mov ebx, eax                    ; save LCM (assumes fits in 32-bit)

    ; -------- Optional console output (extra marks) --------
    lea edx, outLabel
    call PrintZStr
    mov eax, ebx
    call PrintU32
    lea edx, nl
    call PrintZStr

    ; Required: exit code carries the result
    invoke ExitProcess, ebx
main ENDP

END main