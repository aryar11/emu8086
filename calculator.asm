name "Calculator" 

org 100h

.DATA                  
    prompt_msg DB 'Enter a number: $'
    second_num DB 'Enter your second number: $'
    operation DB 'What operation would you like to do (+, -, *, /, ^)? $'
    result DB 'Result: $'
    
    operationChar DB ?
    buffer DB 6 DUP('$')  ; Reserve space for number conversion
    buffer_size   DW $-buffer     ; Size of the buffer
    IntegerPart DW ?
    DecimalPart DW ?
.CODE
    start:
        ; Print the prompt message
        mov ah, 09h
        lea dx, prompt_msg
        int 21h

        ;Get number input
        call SCAN_NUM
        mov bx, cx ; first num is stored in bx register

        ; Print new line
        call newLine

        ; Get operation char
        mov dx, offset operation
        mov ah, 9
        int 21h

        mov ah, 1
        int 21h
        mov dl, al ;operation char is in dl

        ;store char in memory
        lea si, operationChar
        mov [si], dl

        call newLine
        
        ;Get second value
        mov ah, 09h
        lea dx, second_num
        int 21h
        ; Second number input
        call SCAN_NUM ; Saves to CX register
        
        call newLine
        mov dl, [si]
        ; Checking if its "+"
        cmp dl, 2Bh 
        je add
        ; Checking if its "-"
        cmp dl, 2Dh
        je sub
        ; Checking if its "*"
        cmp dl, 2Ah
        je multiplication
        ; Checking if its "/"
        cmp dl, 2Fh
        je division  
        ; Checking if its "^"
        cmp dl, 5Eh
        je exponent
        ; Checking if its "%"
        cmp dl, 25h
        je modulus
    terminate:             
        ; Terminate program
        mov ax, 4c00h
        int 21h
        ret

    add:
        add cx, bx ; Do operation

        ;Print string
        mov ah, 09h
        lea dx, result
        int 21h

        mov ax, cx
        call PRINT_NUM
        
        call newLine
        jmp start
    sub:
        sub bx, cx ; Do operation

        ;Print string
        mov ah, 09h
        lea dx, result
        int 21h

        mov ax, cx
        call PRINT_NUM
        call newLine
        jmp start
    multiplication:
        mov ax, bx
        imul cx ; Do operation
        mov cx, ax
        ;Print string
        mov ah, 09h
        lea dx, result
        int 21h

        mov ax, cx
        call PRINT_NUM
        call newLine
        jmp start

    division:
        mov ax, bx         
        mov dx, 0           
        mov bx, 100d        ; load 100 into bx to multiply
        imul bx              ; dx:ax = ax * bx (100 * dividend)
        idiv cx              ; ax = Quotient,dx = Remainder
        ; ax = integer part of the result * 100
        ; dx contains the remainder of the division 

        ; round to nearest 100th
        shl dx, 1
        cmp dx, cx
        jl l1
        inc ax
    l1:
        cwd
        ;mov dx, 0 
        idiv hundred
        mov IntegerPart, AX
        mov DecimalPart, DX


        ; Print the result
        lea dx, Result
        mov ah, 09h
        int 21h

        ; Print the integer part
        mov ax, IntegerPart
        call PRINT_NUM
        
        ; Print the decimal point
        mov dl, '.'
        mov ah, 2
        int 21h

        ; Print the decimal part (fraction)
        mov ax, DecimalPart
        call PRINT_NUM
        call newLine
        call newLine
        jmp start
    modulus:
        ; MODULUS DOES NOT WORK, THROWS OVERFLOW FOR SOME REASON
        mov al, bl
        div cl 

        mov ax, dx ; remainer stored in dx
        call PRINT_NUM

        call newLine
        call newLine
        jmp start
    exponent:
        mov ax, 1d
        or cx, cx
        jz exp_done

    multiply_loop:
        imul bx
        dec cx
        jz exp_done
        jmp multiply_loop
    exp_done:
        call PRINT_NUM
        call newLine
        call newLine
        jmp start
    newLine:
        mov ah, 0Eh         ; Teletype output function of BIOS
        mov al, 0Dh         ; Carriage return (CR)
        int 10h             ; Call BIOS
        mov al, 0Ah         ; Line feed (LF)
        int 10h             ; Call BIOS again
        ret

; Copied functions from emu8086.inc

; this macro defines a procedure to print a null terminated
; string at current cursor position, receives address of string in DS:SI
DEFINE_PRINT_STRING     MACRO
LOCAL   next_char, printed, skip_proc_print_string

; protect from wrong definition location:
JMP     skip_proc_print_string

PRINT_STRING PROC NEAR
PUSH    AX      ; store registers...
PUSH    SI      ;

next_char:      
        MOV     AL, [SI]
        CMP     AL, 0
        JZ      printed
        INC     SI
        MOV     AH, 0Eh ; teletype function.
        INT     10h
        JMP     next_char
printed:

POP     SI      ; re-store registers...
POP     AX      ;

RET
PRINT_STRING ENDP

skip_proc_print_string:

DEFINE_PRINT_STRING     ENDM



; get a null terminated string from keyboard,
; write it to buffer at ds:di, maximum buffer size is set in dx.
; 'enter' stops the input.
get_string      proc    near
push    ax
push    cx
push    di
push    dx

mov     cx, 0                   ; char counter.

cmp     dx, 1                   ; buffer too small?
jbe     empty_buffer            ;

dec     dx                      ; reserve space for last zero.


;============================
; eternal loop to get
; and processes key presses:

wait_for_key:

mov     ah, 0                   ; get pressed key.
int     16h

cmp     al, 0Dh                  ; 'return' pressed?
jz      exit


cmp     al, 8                   ; 'backspace' pressed?
jne     add_to_buffer
jcxz    wait_for_key            ; nothing to remove!
dec     cx
dec     di
putc    8                       ; backspace.
putc    ' '                     ; clear position.
putc    8                       ; backspace again.
jmp     wait_for_key

add_to_buffer:

        cmp     cx, dx          ; buffer is full?
        jae     wait_for_key    ; if so wait for 'backspace' or 'return'...

        mov     [di], al
        inc     di
        inc     cx
        
        ; print the key:
        mov     ah, 0eh
        int     10h

jmp     wait_for_key
;============================

exit:

; terminate by null:
mov     [di], 0

empty_buffer:

pop     dx
pop     di
pop     cx
pop     ax
ret
get_string      endp


; this macro prints a string that is given as a parameter, example:
; PRINTN 'hello world!'
; the same as PRINT, but new line is automatically added.
PRINTN   MACRO   sdat
LOCAL   next_char, s_dcl, printed, skip_dcl

PUSH    AX      ; store registers...
PUSH    SI      ;

JMP     skip_dcl        ; skip declaration.
        s_dcl DB sdat, 13, 10, 0

skip_dcl:
        LEA     SI, s_dcl
        
next_char:      
        MOV     AL, CS:[SI]
        CMP     AL, 0
        JZ      printed
        INC     SI
        MOV     AH, 0Eh ; teletype function.
        INT     10h
        JMP     next_char
printed:

POP     SI      ; re-store registers...
POP     AX      ;
ENDM


; turns off the cursor:
CURSOROFF       MACRO
        PUSH    AX
        PUSH    CX
        MOV     AH, 1
        MOV     CH, 28h
        MOV     CL, 09h
        INT     10h
        POP     CX
        POP     AX
ENDM



; turns on the cursor:
CURSORON        MACRO
        PUSH    AX
        PUSH    CX
        MOV     AH, 1
        MOV     CH, 08h
        MOV     CL, 09h
        INT     10h
        POP     CX
        POP     AX
ENDM

; sets current cursor
; position:
GOTOXY  MACRO   col, row
        PUSH    AX
        PUSH    BX
        PUSH    DX
        MOV     AH, 02h
        MOV     DH, row
        MOV     DL, col
        MOV     BH, 0
        INT     10h
        POP     DX
        POP     BX
        POP     AX
ENDM





PUTC    MACRO   char
        PUSH    AX
        MOV     AL, char
        MOV     AH, 0Eh
        INT     10h     
        POP     AX
ENDM

SCAN_NUM        PROC    NEAR
        PUSH    DX
        PUSH    AX
        PUSH    SI
        
        MOV     CX, 0

        ; reset flag:
        MOV     CS:make_minus, 0

next_digit:

        ; get char from keyboard
        ; into AL:
        MOV     AH, 00h
        INT     16h
        ; and print it:
        MOV     AH, 0Eh
        INT     10h

        ; check for MINUS:
        CMP     AL, '-'
        JE      set_minus

        ; check for ENTER key:
        CMP     AL, 0Dh  ; carriage return?
        JNE     not_cr
        JMP     stop_input
not_cr:


        CMP     AL, 8                   ; 'BACKSPACE' pressed?
        JNE     backspace_checked
        MOV     DX, 0                   ; remove last digit by
        MOV     AX, CX                  ; division:
        DIV     CS:ten                  ; AX = DX:AX / 10 (DX-rem).
        MOV     CX, AX
        PUTC    ' '                     ; clear position.
        PUTC    8                       ; backspace again.
        JMP     next_digit
backspace_checked:


        ; allow only digits:
        CMP     AL, '0'
        JAE     ok_AE_0
        JMP     remove_not_digit
ok_AE_0:        
        CMP     AL, '9'
        JBE     ok_digit
remove_not_digit:       
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered not digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for next input.       
ok_digit:


        ; multiply CX by 10 (first time the result is zero)
        PUSH    AX
        MOV     AX, CX
        MUL     CS:ten                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX

        ; check if the number is too big
        ; (result should be 16 bits)
        CMP     DX, 0
        JNE     too_big

        ; convert from ASCII code:
        SUB     AL, 30h

        ; add AL to CX:
        MOV     AH, 0
        MOV     DX, CX      ; backup, in case the result will be too big.
        ADD     CX, AX
        JC      too_big2    ; jump if the number is too big.

        JMP     next_digit

set_minus:
        MOV     CS:make_minus, 1
        JMP     next_digit

too_big2:
        MOV     CX, DX      ; restore the backuped value before add.
        MOV     DX, 0       ; DX was zero before backup!
too_big:
        MOV     AX, CX
        DIV     CS:ten  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
        MOV     CX, AX
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for Enter/Backspace.
        
        
stop_input:
        ; check flag:
        CMP     CS:make_minus, 0
        JE      not_minus
        NEG     CX
not_minus:

        POP     SI
        POP     AX
        POP     DX
        RET
make_minus      DB      ?       ; used as a flag.
SCAN_NUM        ENDP



CLEAR_SCREEN PROC NEAR
        PUSH    AX      ; store registers...
        PUSH    DS      ;
        PUSH    BX      ;
        PUSH    CX      ;
        PUSH    DI      ;

        MOV     AX, 40h
        MOV     DS, AX  ; for getting screen parameters.
        MOV     AH, 06h ; scroll up function id.
        MOV     AL, 0   ; scroll all lines!
        MOV     BH, 07  ; attribute for new lines.
        MOV     CH, 0   ; upper row.
        MOV     CL, 0   ; upper col.
        MOV     DI, 84h ; rows on screen -1,
        MOV     DH, [DI] ; lower row (byte).
        MOV     DI, 4Ah ; columns on screen,
        MOV     DL, [DI]
        DEC     DL      ; lower col.
        INT     10h

        ; set cursor position to top
        ; of the screen:
        MOV     BH, 0   ; current page.
        MOV     DL, 0   ; col.
        MOV     DH, 0   ; row.
        MOV     AH, 02
        INT     10h

        POP     DI      ; re-store registers...
        POP     CX      ;
        POP     BX      ;
        POP     DS      ;
        POP     AX      ;

        RET
CLEAR_SCREEN ENDP

; This macro defines a procedure that prints number in AX,
; used with PRINT_NUM_UNS to print signed numbers:
; Requires DEFINE_PRINT_NUM_UNS !!!
PRINT_NUM       PROC    NEAR
        PUSH    DX
        PUSH    AX

        CMP     AX, 0
        JNZ     not_zero

        PUTC    '0'
        JMP     printed

not_zero:
        ; the check SIGN of AX,
        ; make absolute if it's negative:
        CMP     AX, 0
        JNS     positive
        NEG     AX

        PUTC    '-'

positive:
        CALL    PRINT_NUM_UNS
printed:
        POP     AX
        POP     DX
        RET
PRINT_NUM       ENDP

skip_proc_print_num:

DEFINE_PRINT_NUM        ENDM



PRINT_NUM_UNS   PROC    NEAR
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX

        ; flag to prevent printing zeros before number:
        MOV     CX, 1

        ; (result of "/ 10000" is always less or equal to 9).
        MOV     BX, 10000       ; 2710h - divider.

        ; AX is zero?
        CMP     AX, 0
        JZ      print_zero

begin_print:

        ; check divider (if zero go to end_print):
        CMP     BX,0
        JZ      end_print

        ; avoid printing zeros before number:
        CMP     CX, 0
        JE      calc
        ; if AX<BX then result of DIV will be zero:
        CMP     AX, BX
        JB      skip
calc:
        MOV     CX, 0   ; set flag.

        MOV     DX, 0
        DIV     BX      ; AX = DX:AX / BX   (DX=remainder).

        ; print last digit
        ; AH is always ZERO, so it's ignored
        ADD     AL, 30h    ; convert to ASCII code.
        PUTC    AL


        MOV     AX, DX  ; get remainder from last div.

skip:
        ; calculate BX=BX/10
        PUSH    AX
        MOV     DX, 0
        MOV     AX, BX
        DIV     CS:ten  ; AX = DX:AX / 10   (DX=remainder).
        MOV     BX, AX
        POP     AX

        JMP     begin_print
        
print_zero:
        PUTC    '0'
        
end_print:

        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
PRINT_NUM_UNS   ENDP


ten             DW      10      ; used as multiplier/divider by SCAN_NUM & PRINT_NUM_UNS.
hundred         DW      100
END