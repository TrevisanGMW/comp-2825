section .data
    ; Terminator 0 is ASCII/Binary for NUL - Length is extracted using functions
    initialMsg db 'Guess the secret number between 0 and 5:', 0 
    incorrect db 'Sorry, wrong number! It was: ', 0
    correct db 'You guessed correctly!', 0

section .bss
    input: resb 255          ; Variable used to store user input
    num: resb 5              ; Variable used to store secret number

section .text
    global _start            ; Main function / Entry point

_start:
     ; Generate "Random" Number between 0 and 5
    mov eax, 13              ; Get Time
    int 80h                  ; Call kernel
    mov ebx, 6               ; Maximum value for the random number
    div ebx                  ; Divide queried time
    mov eax, edx             ; Get remainder (num 0 to 5)
    mov [num], eax           ; Store random number for later
    
    ; Print initial message
    mov ebx, 0               ; Clear ebx 
    mov eax, initialMsg      ; Pointer to the message
    call sprintLF

    ; ; Debugging (print generated number)
    ; mov eax, [num]           ; Move variable num into eax for printing
    ; call iprint              ; print eax
    
    ; Read user input
    mov edx, 255             ; Number of bytes to read
    mov ecx, input           ; Reserved space to store our input (buffer)
    mov ebx, 0               ; Read from the STDIN file
    mov eax, 3               ; Invoke SYS_READ (kernel opcode 3)
    int 0x80                 ; Call kernel
    
    ; Convert user input to integer
    mov eax, input           ; Move user input to eax
    call atoi                ; Convert user input to integer
    ; call iprint              ; Print for debugging
    mov [input], eax         ; Move converted int back to variable input
    
    ; Compare numbers and print result
    mov al, [input]          ; Move int user input to al
    cmp al, [num]            ; Compare generated number with al (input)
    jne guessBad             ; Jump if Condition Is Met (same number)
    jmp guessGood            ; In case it doesn't jump, the number is wrong
    call quit                ; Exit program

guessGood:
    mov eax, correct         ; Pointer to the message
    call sprint              ; Setup "aex" and "abx" then make kernel call
    call quit                ; exit program
    
guessBad:
    mov eax, incorrect       ; Pointer to the message
    call sprint              ; Setup "aex" and "abx" then make kernel call
    mov eax, [num]           ; Move generated number to eax for printing
    call iprint              ; Print generated number
    call quit                ; Exit program


;------------------------------------------
; void iprint(Integer number)
; Integer printing function
iprint:
    push    eax             ; Preserve eax on the stack to be restored after function runs
    push    ecx             ; Preserve ecx on the stack to be restored after function runs
    push    edx             ; Preserve edx on the stack to be restored after function runs
    push    esi             ; Preserve esi on the stack to be restored after function runs
    mov     ecx, 0          ; Counter of how many bytes we need to print in the end
 
divideLoop:
    inc     ecx             ; Count each byte to print - number of characters
    mov     edx, 0          ; Empty edx
    mov     esi, 10         ; Mov 10 into esi
    idiv    esi             ; Divide eax by esi
    add     edx, 48         ; Convert edx to it's ascii representation - edx holds the remainder after a divide instruction
    push    edx             ; Push edx (string representation of an intger) onto the stack
    cmp     eax, 0          ; Can the integer be divided anymore?
    jnz     divideLoop      ; Jump if not zero to the label divideLoop
 
printLoop:
    dec     ecx             ; Count down each byte that we put on the stack
    mov     eax, esp        ; Mov the stack pointer into eax for printing
    call    sprint          ; Call our string print function
    pop     eax             ; Remove last character from the stack to move esp forward
    cmp     ecx, 0          ; Have we printed all bytes we pushed onto the stack?
    jnz     printLoop       ; Jump is not zero to the label printLoop
 
    pop     esi             ; Restore esi from the value we pushed onto the stack at the start
    pop     edx             ; Restore edx from the value we pushed onto the stack at the start
    pop     ecx             ; Restore ecx from the value we pushed onto the stack at the start
    pop     eax             ; Restore eax from the value we pushed onto the stack at the start
    ret
 
 
;------------------------------------------
; void sprint(String message)
; String printing function
sprint:
    push    edx             ; Preserve edx on the stack to be restored after function runs
    push    ecx             ; Preserve ecx on the stack to be restored after function runs
    push    ebx             ; Preserve ebx on the stack to be restored after function runs
    push    eax             ; Preserve eax on the stack to be restored after function runs
    call    slen            ; Get string length (output: eax)
 
    mov     edx, eax        ; Move slen value to edx
    pop     eax             ; Restore original eax
 
    mov     ecx, eax        ; Move eax to ecx in preparation for system call
    mov     ebx, 1          ; File descriptor for stdout
    mov     eax, 4          ; System call for write
    int     80h             ; Call kernel
 
    pop     ebx             ; Restore ebx from the value we pushed onto the stack at the start
    pop     ecx             ; Restore ecx from the value we pushed onto the stack at the start
    pop     edx             ; Restore edx from the value we pushed onto the stack at the start
    ret                     ; Return
   

;------------------------------------------
; int slen(String message) - Modified to use 0x0a ("\n") as terminator 
; String length calculation function
slen:
    push    ebx             ; Preserve ebx on the stack to be restored after function runs
    mov     ebx, eax        ; Move eax into ebx to free it for byte search (next char)
 
nextchar:
    cmp     byte [eax], 0   ; Compare byte address in memory to find terminator char (0 in this case)
    jz      finished        ; Found terminator, end function
    inc     eax             ; Increment aex 
    jmp     nextchar        ; Move to the next character
 
finished:
    sub     eax, ebx        ; Subtract bx from eax
    pop     ebx             ; Restore ebx from the value we pushed onto the stack at the start
    ret                     ; Return


;------------------------------------------
; void sprintLF(String message)
; String printing with line feed function
sprintLF:
    call sprint             ; Pass through, print string before adding new line
    push  eax               ; Push eax onto the stack to preserve it while we use the eax register
    mov eax, 0x0a           ; Move 0x0a into eax - 0x0a is the ASCII for a linefeed (aka 0Ah or "\n")
    push eax                ; Push the linefeed onto the stack so we can get the address
    mov eax, esp            ; Move the address of the current stack pointer into eax for sprint
    call sprint             ; Call our sprint function
    pop eax                 ; Remove our linefeed character from the stack
    pop eax                 ; Restore the original value of eax before our function was called
    ret                     ; Return to our program


;------------------------------------------
; int atoi(Integer number)
; Ascii to integer function (atoi)
atoi:
    push    ebx             ; Preserve ebx on the stack to be restored after function runs
    push    ecx             ; Preserve ecx on the stack to be restored after function runs
    push    edx             ; Preserve edx on the stack to be restored after function runs
    push    esi             ; Preserve esi on the stack to be restored after function runs
    mov     esi, eax        ; Move pointer in eax into esi (our number to convert)
    mov     eax, 0          ; Initialise eax with decimal value 0
    mov     ecx, 0          ; Initialise ecx with decimal value 0
 
.multiplyLoop:
    xor     ebx, ebx        ; Resets both lower and uppper bytes of ebx to be 0
    mov     bl, [esi+ecx]   ; Move a single byte into ebx register's lower half
    cmp     bl, 48          ; Compare ebx register's lower half value against ascii value 48 (char value 0)
    jl      .finished       ; Jump if less than to label finished
    cmp     bl, 57          ; Compare ebx register's lower half value against ascii value 57 (char value 9)
    jg      .finished       ; Jump if greater than to label finished
 
    sub     bl, 48          ; Convert ebx register's lower half to decimal representation of ascii value
    add     eax, ebx        ; Add ebx to our interger value in eax
    mov     ebx, 10         ; Move decimal value 10 into ebx
    mul     ebx             ; Multiply eax by ebx to get place value
    inc     ecx             ; Increment ecx (our counter register)
    jmp     .multiplyLoop   ; Continue multiply loop
 
.finished:
    cmp     ecx, 0          ; Compare ecx register's value against decimal 0 (our counter register)
    je      .restore        ; Jump if equal to 0 (no integer arguments were passed to atoi)
    mov     ebx, 10         ; Move decimal value 10 into ebx
    div     ebx             ; Divide eax by value in ebx (in this case 10)
 
.restore:
    pop     esi             ; Restore esi from the value we pushed onto the stack at the start
    pop     edx             ; Restore edx from the value we pushed onto the stack at the start
    pop     ecx             ; Restore ecx from the value we pushed onto the stack at the start
    pop     ebx             ; Restore ebx from the value we pushed onto the stack at the start
    ret                     ; Return
    
    
; ----------------------------------------
; void exit()
; Exit program and restore resources
quit:
    ; Exit the program
    mov eax, 1              ; System call for exit
    mov ebx, 0              ; Process' exit code (0 = no errors)
    int 0x80                ; Call the kernel
    ret                     ; Return (Incase using as function)
    