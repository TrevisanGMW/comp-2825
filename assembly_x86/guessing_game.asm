section .data
    initialMsg db 'Guess the secret number between 0 and 5:', 0x0a
    initialMsgLen equ $ - initialMsg
    incorrect db 'Sorry, wrong number! It was: '
    incorrectLen equ $ - incorrect
    correct db 'You guessed correctly!', 0x0a
    correctLen equ $ - correct

section .bss
    input: resb 255 
    num: resb 5

section .text
    global _start

_start:
    ; Generate "Random" Number between 0 and 5
    mov eax, 13    ; Get Time
	int 80h        ; call kernel
    mov ebx, 6     ; Maximum value for the random number
    div ebx        ; Divide queried time
    mov eax, edx   ; Get remainder (num 0 to 5)
    mov [num], eax ; Store random number for later
    
    ; Print initial message
    mov ecx, initialMsg      ; Pointer to the message
    mov edx, initialMsgLen      ; Length of the message
    call print
    
    ; ; Debugging (print generated number)
    ; mov eax, [num]
    ; call iprint
    
    ; Read user input
    mov edx, 255        ; number of bytes to read
    mov ecx, input      ; reserved space to store our input (buffer)
    mov ebx, 0          ; read from the STDIN file
    mov eax, 3          ; invoke SYS_READ (kernel opcode 3)
    int 0x80            ; call kernel
    
    ; Convert user input to integer
    mov eax, input
    call atoi 
    ; call iprint   ; Print for debugging
    mov [input], eax
    
    ; Compare numbers and print result
    mov al, [input]
    cmp al, [num]
    jne guessBad
    jmp guessGood
    call quit


guessGood:
    mov ecx, correct     ; Pointer to the message
    mov edx, correctLen  ; Length of the message
    call print           ; Setup "aex" and "abx" then make kernel call
    call quit
    
guessBad:
    mov ecx, incorrect     ; Pointer to the message
    mov edx, incorrectLen  ; Length of the message
    call print             ; Setup "aex" and "abx" then make kernel call
    mov eax, [num]
    call iprint
    call quit

;------------------------------------------
; void print (String message)
; String printing function
print:
    ; Write the number to the console
    mov eax, 4        ; System call for write
    mov ebx, 1        ; File descriptor for stdout
    int 0x80          ; Call the kernel
    ret

; ----------------------------------------
; void exit()
; Exit program and restore resources
quit:
    ; Exit the program
    mov eax, 1        ; System call for exit
    mov ebx, 0        ; Process' exit code
    int 0x80          ; Call the kernel
    ret               ; Return (Incase using as function)
    
;------------------------------------------
; void iprint(Integer number)
; Integer printing function
iprint:
    push    eax             ; preserve eax on the stack to be restored after function runs
    push    ecx             ; preserve ecx on the stack to be restored after function runs
    push    edx             ; preserve edx on the stack to be restored after function runs
    push    esi             ; preserve esi on the stack to be restored after function runs
    mov     ecx, 0          ; counter of how many bytes we need to print in the end
 
divideLoop:
    inc     ecx             ; count each byte to print - number of characters
    mov     edx, 0          ; empty edx
    mov     esi, 10         ; mov 10 into esi
    idiv    esi             ; divide eax by esi
    add     edx, 48         ; convert edx to it's ascii representation - edx holds the remainder after a divide instruction
    push    edx             ; push edx (string representation of an intger) onto the stack
    cmp     eax, 0          ; can the integer be divided anymore?
    jnz     divideLoop      ; jump if not zero to the label divideLoop
 
printLoop:
    dec     ecx             ; count down each byte that we put on the stack
    mov     eax, esp        ; mov the stack pointer into eax for printing
    call    sprint          ; call our string print function
    pop     eax             ; remove last character from the stack to move esp forward
    cmp     ecx, 0          ; have we printed all bytes we pushed onto the stack?
    jnz     printLoop       ; jump is not zero to the label printLoop
 
    pop     esi             ; restore esi from the value we pushed onto the stack at the start
    pop     edx             ; restore edx from the value we pushed onto the stack at the start
    pop     ecx             ; restore ecx from the value we pushed onto the stack at the start
    pop     eax             ; restore eax from the value we pushed onto the stack at the start
    ret
 
    
;------------------------------------------
; void sprint(String message)
; String printing function
sprint:
    push    edx
    push    ecx
    push    ebx
    push    eax
    call    slen
 
    mov     edx, eax
    pop     eax
 
    mov     ecx, eax
    mov     ebx, 1
    mov     eax, 4
    int     80h
 
    pop     ebx
    pop     ecx
    pop     edx
    ret
    
;------------------------------------------
; int slen(String message)
; String length calculation function
slen:
    push    ebx
    mov     ebx, eax
 
nextchar:
    cmp     byte [eax], 0
    jz      finished
    inc     eax
    jmp     nextchar
 
finished:
    sub     eax, ebx
    pop     ebx
    ret
    
;------------------------------------------
; int atoi(Integer number)
; Ascii to integer function (atoi)
atoi:
    push    ebx             ; preserve ebx on the stack to be restored after function runs
    push    ecx             ; preserve ecx on the stack to be restored after function runs
    push    edx             ; preserve edx on the stack to be restored after function runs
    push    esi             ; preserve esi on the stack to be restored after function runs
    mov     esi, eax        ; move pointer in eax into esi (our number to convert)
    mov     eax, 0          ; initialise eax with decimal value 0
    mov     ecx, 0          ; initialise ecx with decimal value 0
 
.multiplyLoop:
    xor     ebx, ebx        ; resets both lower and uppper bytes of ebx to be 0
    mov     bl, [esi+ecx]   ; move a single byte into ebx register's lower half
    cmp     bl, 48          ; compare ebx register's lower half value against ascii value 48 (char value 0)
    jl      .finished       ; jump if less than to label finished
    cmp     bl, 57          ; compare ebx register's lower half value against ascii value 57 (char value 9)
    jg      .finished       ; jump if greater than to label finished
 
    sub     bl, 48          ; convert ebx register's lower half to decimal representation of ascii value
    add     eax, ebx        ; add ebx to our interger value in eax
    mov     ebx, 10         ; move decimal value 10 into ebx
    mul     ebx             ; multiply eax by ebx to get place value
    inc     ecx             ; increment ecx (our counter register)
    jmp     .multiplyLoop   ; continue multiply loop
 
.finished:
    cmp     ecx, 0          ; compare ecx register's value against decimal 0 (our counter register)
    je      .restore        ; jump if equal to 0 (no integer arguments were passed to atoi)
    mov     ebx, 10         ; move decimal value 10 into ebx
    div     ebx             ; divide eax by value in ebx (in this case 10)
 
.restore:
    pop     esi             ; restore esi from the value we pushed onto the stack at the start
    pop     edx             ; restore edx from the value we pushed onto the stack at the start
    pop     ecx             ; restore ecx from the value we pushed onto the stack at the start
    pop     ebx             ; restore ebx from the value we pushed onto the stack at the start
    ret