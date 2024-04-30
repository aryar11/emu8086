name "mouse tracker"

org 100h

.DATA
msg DB 'HELLO$'
mouseX DW 0
mouseY DW 0
d1 dw 655
.CODE

print macro x, y, attrib, sdat
LOCAL   s_dcl, skip_dcl, s_dcl_end
    pusha
    mov dx, cs
    mov es, dx
    mov ah, 13h
    mov al, 1
    mov bh, 0
    mov bl, attrib
    mov cx, offset s_dcl_end - offset s_dcl
    mov dl, x
    mov dh, y
    mov bp, offset s_dcl
    int 10h
    popa
    jmp skip_dcl
    s_dcl DB sdat
    s_dcl_end DB 0
    skip_dcl:    
endm



MAIN PROC
    ; Check if mouse installed
    mov ax, 0 
    int 33h
    cmp ax, 0
    je no_mouse
    ; disable blinking
    mov ax, 1003h 
    mov bx, 0        
    int 10h       
    ; hide text cursor:
    mov ch, 32
    mov ah, 1
    int 10h
    ; Clear screen
    call clear_screen
    ; display mouse cursor:
    mov ax, 1
    int 33h
    ;change cursor size
    mov ah, 01h       
    mov ch, 1 
    mov cl, 2 
    int 10h
    ;mov ah, 00
    ;mov al, 13h       ; set screen to 256 colors, 320x200 pixels. 
    ;int 10h
    ;call get_dimension
    print 25, 10, 0010_1011b, 'Welcome to my mouse tracker!' 
    print 24, 11, 0010_1011b, 'Hold down right click to exit'   
; Cursor tracker
tracking_loop:    
;    mov ah, 3
;    mov bh, 0
;    int 10h
    mov ax, 0
    mov bx, 0
    mov ax, 3
    int 33h
    cmp bx, 2
    je end_program
    cmp cx, [mouseX]
    jne print_x
    jmp tracking_loop
no_mouse:
    call clear_screen
    print 25, 7, 07h, 'Sorry, no mouse detected. Exiting program.'
    mov ax, 4c00h
    int 21h   
end_program:
    call clear_screen
    print 20, 10, 04h, 'Looks like you right-clicked, exiting...'  
    mov ax, 4c00h
    int 21h   
clear_screen:
    ; Clear screen
    pusha
    mov ax, 0600h
    mov bh, 0000_1111b
    mov cx, 0
    mov dh, 24
    mov dl, 79
    int 10h
    popa
    ret

print_x:  
    mov mouseX, cx
    mov mouseY, dx
    print 0, 0, 07h, 'x =      '   
    mov dh, 0
    mov dl, 4
    mov bh, 0
    mov ah, 2
    int 10h
    ;print x value
    mov ax, mouseX
    call print_ax
    ;jmp print_y
print_y:
    print 0, 1, 07h, 'y =      '   
    ;move cursor
    mov dh, 1
    mov dl, 4
    mov bh, 0
    mov ah, 2
    int 10h
    ;print x value
    mov ax, 0
    mov ax, mouseY
    call print_ax
    jmp tracking_loop
color_pixel: ; Function only works in video mode
   ;Draw pixel
   ; pusha
   ; mov ax, 0
   ; mov ah, 0ch 
   ; mov cx, mouseX
   ; mov dx, mouseY
   ; mov al, 4
   ; int 10h
    jmp tracking_loop
get_dimension:
    mov ax, 0f00h
    int 10h
    mov bl, ah
    
    shr bl, 1
    sub bl, 13
    ret

;Print int in ax 
print_ax proc
cmp ax, 0
jne print_ax_r
    push ax
    mov al, '0'
    mov ah, 0eh
    int 10h
    pop ax
    ret 
print_ax_r:
    pusha
    mov dx, 0
    cmp ax, 0
    je pn_done
    mov bx, 10
    div bx    
    call print_ax_r
    mov ax, dx
    add al, 30h
    mov ah, 0eh
    int 10h    
    jmp pn_done
pn_done:
    popa  
    ret  
endp
END MAIN
