; ==========================================================
; CP4UA53O - Computer Architecture (Element 2)
; Program 3: Multiply your student number by 3 and print result
; Student ID: 34125387 (stored as integer, not a string)
; Toolchain target: x86 (Win32) MASM in Visual Studio 2022/2026
; Requirement: integer -> ASCII, covered cases 0 to overflow->(4294967295)
; ==========================================================

.386                       ; enable 80386+ instruction set (32-bit registers)
.model flat, stdcall       ; flat memory model (Win32), stdcall calling convention
option casemap:none        ; disable automatic case mapping (symbols are case-sensitive)
.stack 4096                ; reserve 4096 bytes of stack space

includelib kernel32.lib    ; link against kernel32.lib for Win32 API functions

ExitProcess   PROTO stdcall, dwExitCode:DWORD
                           ; prototype for ExitProcess(dwExitCode) - terminates process
GetStdHandle  PROTO stdcall, nStdHandle:DWORD
                           ; prototype for GetStdHandle(nStdHandle) - returns standard handle
WriteConsoleA PROTO stdcall, \
    hConsoleOutput:DWORD,  ; console HANDLE parameter
    lpBuffer:PTR BYTE,     ; pointer to buffer containing characters
    nNumberOfCharsToWrite:DWORD, ; number of characters to write (count of chars)
    lpNumberOfCharsWritten:PTR DWORD, ; pointer to DWORD that receives number of chars written
    lpReserved:DWORD       ; reserved (must be NULL)

STD_OUTPUT_HANDLE equ -11  ; constant used with GetStdHandle to request standard output

.data
    studentID   dd 34125387   ; student ID stored as 32-bit integer
    multiplier  dd 3          ; multiplier constant (3)

    nl          db 13,10      ; CR (13), LF (10) pair for newline (not null-terminated)
    outLabel    db "StudentID * 3 = ",0 ; null-terminated label string
    errMsg      db "ERROR: product overflow (>= 2^32)",13,10,0 ; error message

    buf         db 12 dup(0)  ; 12-byte buffer: supports up to 11 digits + null terminator
    charsW      dd 0          ; DWORD used by WriteConsoleA to receive count of chars written

.code                     ; begin code section

; ----------------------------------------------------------
; PrintZStr: write a null-terminated string to console
; IN: EDX = address of null-terminated string
; ----------------------------------------------------------
PrintZStr PROC
    pushad                    ; save general-purpose registers
    invoke GetStdHandle, STD_OUTPUT_HANDLE ; get console handle, returned in EAX
    mov ebx, eax              ; save console handle in EBX for WriteConsoleA

    mov ecx, 0                ; set length counter to 0
len_loop:
    cmp byte ptr [edx + ecx], 0 ; test for null terminator at EDX+ECX
    je  len_done              ; if null found, break loop
    inc ecx                   ; increment length counter
    jmp len_loop              ; repeat length scan
len_done:
    invoke WriteConsoleA, ebx, edx, ecx, ADDR charsW, 0
                              ; write ECX characters from [EDX] to console
    popad                     ; restore registers
    ret
PrintZStr ENDP

; -------------------------------------------------------------
; PrintNL: write CRLF to console (fixed length = 2 characters)
; -------------------------------------------------------------
PrintNL PROC
    pushad 				      ; save general-purpose registers
    invoke GetStdHandle, STD_OUTPUT_HANDLE ; get console handle
    mov ebx, eax              ; store handle in EBX
    invoke WriteConsoleA, ebx, ADDR nl, 2, ADDR charsW, 0
                              ; write two characters (CR, LF)
    popad                     ; restore registers
    ret                       ; return
PrintNL ENDP

; ---------------------------------------------------------------------------
; U32ToDecStr: convert unsigned 32-bit in EAX to ASCII decimal string in buf
; OUT: EDX = pointer to first digit, ECX = digit count (excludes null)
; ---------------------------------------------------------------------------
U32ToDecStr PROC
    push ebx                  ; preserve EBX (divisor)
    push esi                  ; preserve ESI (working value)
    push edi                  ; preserve EDI (buffer pointer)

    lea edi, buf              ; EDI = address of buffer start
    add edi, 11               ; point to buf + 11 (reserve last byte for null)
    mov byte ptr [edi], 0     ; place null terminator at buffer end
    dec edi                   ; move EDI to position for least-significant digit

    mov ebx, 10               ; EBX = divisor 10 for decimal conversion
    mov esi, eax              ; ESI = working copy of value to convert

    test esi, esi             ; test if value == 0
    jnz conv_loop             ; if not zero, enter conversion loop

    mov byte ptr [edi], '0'   ; value is zero: store ASCII '0'
    mov edx, edi              ; EDX points to first digit
    mov ecx, 1                ; ECX = length 1
    jmp conv_done             ; conversion finished

conv_loop:
    mov eax, esi              ; EAX = current working value
    xor edx, edx              ; clear EDX before unsigned DIV (EDX:EAX is dividend)
    div ebx                   ; unsigned divide EDX:EAX by EBX -> quotient in EAX, remainder in EDX
    add dl, '0'               ; convert remainder to ASCII (DL)
    mov byte ptr [edi], dl    ; store ASCII digit at current buffer position
    dec edi                   ; move buffer pointer left for next digit
    mov esi, eax              ; update working value = quotient
    test esi, esi             ; check if more digits remain
    jnz conv_loop             ; if quotient != 0, continue loop

    inc edi                   ; adjust EDI to point to first stored digit
    mov edx, edi              ; EDX = pointer to first digit

    lea eax, buf              ; EAX = buffer start
    add eax, 11               ; EAX = buffer end (address of null)
    sub eax, edx              ; EAX = (buf+11) - firstDigitPtr => digit count
    mov ecx, eax              ; ECX = digit count

conv_done:
    pop edi                   ; restore EDI
    pop esi                   ; restore ESI
    pop ebx                   ; restore EBX
    ret                       ; return with EDX=ptr, ECX=len
U32ToDecStr ENDP

; ----------------------------------------------------------------------------
; PrintU32: print unsigned integer in EAX using U32ToDecStr and WriteConsoleA
; IN: EAX = unsigned 32-bit integer to print
; ----------------------------------------------------------------------------
PrintU32 PROC
    push ebx                  ; preserve EBX
    push eax                  ; preserve EAX (value to print)
    
    ; Get console handle FIRST so we don't clobber string registers later
    invoke GetStdHandle, STD_OUTPUT_HANDLE 
    mov ebx, eax              ; store console handle in EBX
    
    ; Restore value and convert to string
    pop eax                   ; restore value to print into EAX
    call U32ToDecStr          ; convert EAX -> ASCII (Returns: EDX=ptr, ECX=len)
    
    ; Write to console using the safe handle in EBX
    invoke WriteConsoleA, ebx, edx, ecx, ADDR charsW, 0
    
    pop ebx                   ; restore EBX
    ret
PrintU32 ENDP

; ----------------------------------------------------------------------------------------------
; main: multiply studentID by multiplier, print label and result, exit with result as exit code
; ----------------------------------------------------------------------------------------------
main PROC
    mov eax, studentID        ; load studentID into EAX
    mul multiplier            ; unsigned multiply: full product in EDX:EAX
                              ; (EAX = low 32 bits, EDX = high 32 bits)

    test edx, edx 		      ; check if high 32 bits (EDX) are non-zero
    jnz overflow_case         ; if high 32 bits non-zero -> overflow

    mov ebx, eax              ; keep low 32 bits of product in EBX for printing and exit

    lea edx, outLabel         ; EDX = address of label string
    call PrintZStr            ; print "StudentID * 3 = "
    mov eax, ebx              ; move result into EAX for PrintU32
    call PrintU32             ; print numeric result
    call PrintNL              ; print newline (CRLF)

    invoke ExitProcess, ebx   ; exit process and return EBX (low 32 bits of product) as exit code

overflow_case: 		          ; handle overflow case (EDX != 0)
    lea edx, errMsg 		  ; EDX = address of error message string 
    call PrintZStr 		      ; print error message 
    invoke ExitProcess, 1  	  ; exit with error code 1 
main ENDP

END main
