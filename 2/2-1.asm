.386
stack segment use16 stack
    db 500 dup(0)
stack ends

data segment use16
    max_item        equ 1000
    loop_time       equ 1000
    null            db  ?
    auth            db  0
    shop_name       db  'shop', '$'
    customer        db  'customer', '$'
    boss_name       db  'wangnengjie', 0
    boss_pwd        db  '123456', 0

    curr_item       dw  null
    ; dw    in_price, sell_price, in_amount, sell_amount, rate
    item_1          db  'bag', 7 dup(0), 8
                    dw  35, 56, loop_time, 0, ?
    item_2          db  'book', 6 dup(0), 9
                    dw  12, 30, 25, 5, ?
    item_temp       db  max_item - 2 dup('TempValue', 0, 8, 15, 0, 20, 0, 30, 0, 2, 0, ?, ?)

    in_username     db  15
                    db  0
                    db  15 dup(0)
    in_pwd          db  7
                    db  0
                    db  7 dup(0)
    in_item         db  10
                    db  10
                    db  10 dup(0)

    username_hint   db  'Please enter your username: ', '$'
    pwd_hint        db  'Please enter your password: ', '$'
    item_name_hint  db  'Please enter the name of item: ', '$'

    menu_1          db  'User: ', '$'
    menu_2          db  'Current item: ', '$'
    menu_3          db  'Please choose the action:', 13, 10
                    db  '1. Log in', 13, 10
                    db  '2. Search item', 13, 10
                    db  '3. Place an order', 13, 10
                    db  '4. Calculate suggestion rate', 13, 10
                    db  '5. Calculate suggestion rank', 13, 10
                    db  '6. Modify item', 13, 10
                    db  '7. Migrate runtime', 13, 10
                    db  '8. Show head address of code segment', 13, 10
                    db  '9. Exit', 13, 10, '$'

    login_fail_hint db  'Login failed!', '$'
    not_found_hint  db  'Item not found!', '$'
    cho_item_hint   db  'Please choose a item!', '$'
    order_err_hint  db  'Fail to place order!', '$'
data ends

code segment use16
    assume cs:code, ds:data, ss:stack

start:
    mov     ax, data
    mov     ds, ax

entry_point:
    call    print_line
    call    show_menu
    mov     ah, 1
    int     21h
    sub     al, 30h
    call    print_line
    cmp     al, 1
    je      func_1
    cmp     al, 2
    je      func_2
    cmp     al, 3
    je      func_3
    cmp     al, 4
    je      func_4
    cmp     al, 8
    je      func_8
    cmp     al, 9
    je      exit
    jmp     entry_point
func_1:
    call    login
    jmp     entry_point
func_2:
    call    search_item
    jmp     entry_point
func_3:
    mov     ax, 0
    call    TIMER
    mov     cx, loop_time
timer_test_loop:
    call    place_order
    loop    timer_test_loop
    mov     ax, 1
    call    TIMER
    jmp     entry_point
func_4:
    call    calc_all_rate
    jmp     entry_point
func_8:
    call    print_cs
    jmp     entry_point

login proc
    pusha
login_entry:
    mov     auth, 0
    lea     dx, username_hint
    mov     ah, 09h
    int     21h
    lea     dx, in_username
    mov     ah, 0ah
    int     21h
    call    print_line
    cmp     in_username + 2, 13
    je      login_exit
    lea     dx, pwd_hint
    mov     ah, 09h
    int     21h
    lea     dx, in_pwd
    mov     ah, 0ah
    int     21h
    call    print_line
verify_username:
    lea     bx, in_username + 2
    lea     si, boss_name
verify_username_check_loop:
    mov     al, [bx]
    cmp     byte ptr[si], al
    jne     login_fail
    inc     si
    inc     bx
    cmp     byte ptr[si], 0
    jne     verify_username_check_loop
    cmp     byte ptr[bx], 13
    jne     verify_username_check_loop
    jmp     verify_pwd
verify_pwd:
    lea     bx, in_pwd + 2
    lea     si, boss_pwd
verify_pwd_check_loop:
    mov     al, [bx]
    cmp     byte ptr[si], al
    jne     login_fail
    inc     si
    inc     bx
    cmp     byte ptr[si], 0
    jne     verify_pwd_check_loop
    cmp     byte ptr[bx], 13
    jne     verify_pwd_check_loop
    mov     auth, 1
    jmp     login_exit
login_fail:
    lea     dx, login_fail_hint
    mov     ah, 09h
    int     21h
    call    print_line
    jmp     login_entry
login_exit:
    popa
    ret
login endp

search_item proc
    pusha
    lea     dx, item_name_hint
    mov     ah, 09h
    int     21h
    lea     dx, in_item
    mov     ah, 0ah
    int     21h
    call    print_line
    movzx   bx, in_item + 1
    mov     byte ptr in_item+2[bx], 0
    lea     dx, item_1
    mov     cx, max_item
item_loop:
    mov     bx, dx
    lea     si, in_item + 2
check_item:
    mov     al, [bx]
    cmp     byte ptr[si], al
    jne     next_item
    inc     bx
    inc     si
    cmp     byte ptr[si], 0
    jne     check_item
    cmp     byte ptr[bx], 0
    jne     check_item
    jmp     item_found
next_item:
    add     dx, 21
    loop    item_loop   
    jmp     item_not_found
item_not_found:
    lea     dx, not_found_hint
    mov     ah, 09h
    int     21h
    call    print_line
    jmp     search_item_exit
item_found:
    mov     curr_item, dx
search_item_exit:    
    popa
    ret
search_item endp

place_order proc
    pusha
    cmp     curr_item, offset null
    je      place_order_err
    mov     bx, curr_item
    mov     ax, 15[bx]
    cmp     ax, 17[bx]
    je      place_order_err
    mov     ax, 17[bx]
    inc     ax
    mov     17[bx], ax
    call    calc_all_rate
    jmp     place_order_exit
place_order_err:
    lea     dx, order_err_hint
    mov     ah, 09h
    int     21h
    call    print_line
place_order_exit:
    popa
    ret
place_order endp

calc_all_rate proc
    push    ax
    push    cx
    mov     cx, max_item
    jcxz    calc_rate_exit
    lea     ax, item_1
calc_rate_loop:
    call    calc_rate
    add     ax, 21
    loop    calc_rate_loop
calc_rate_exit:
    pop     cx
    pop     ax
    ret
calc_all_rate endp


calc_rate proc
    ; ax point to item
    ; dw in_price(11), sell_price(13), in_amount(15), sell_amount(17), rate(19)
    pushad
    mov     si, ax
    mov     ax, 13[si]
    movzx   bx, byte ptr 10[si]
    mul     bx
    push    dx
    push    ax

    movzx   eax, word ptr 11[si]
    mov     ebx, 1280
    mul     ebx
    pop     ebx
    div     ebx
    push    eax

    movzx   eax, word ptr 17[si]
    shl     eax, 6 ; *64
    xor     edx, edx
    movzx   ebx, word ptr 15[si]
    div     ebx

    mov     ebx, eax
    pop     eax
    add     eax, ebx
    mov     19[si], ax
    popad
    ret
calc_rate endp

print_line proc
    push    ax
    push    dx
    mov     ah, 02h
    mov     dl, 13
    int     21h
    mov     ah, 02h
    mov     dl, 10
    int     21h
    pop     dx
    pop     ax
    ret
print_line endp

show_menu proc
    pusha
    lea dx, menu_1
    mov ah, 09h
    int 21h
    cmp auth, 1
    je show_menu_bname
    lea dx, customer
    mov ah, 09h
    int 21h
    jmp show_menu_p1
show_menu_bname:
    lea si, boss_name
show_menu_loop1:
    mov ah, 02h
    mov dl, [si]
    int 21h
    inc si
    cmp byte ptr[si], 0
    jne show_menu_loop1
show_menu_p1:
    call print_line
    lea dx, menu_2
    mov ah, 09h
    int 21h
    cmp curr_item, offset null
    je show_menu_p2
    mov si, curr_item
show_menu_loop2:
    mov ah, 02h
    mov dl, [si]
    int 21h
    inc si
    cmp byte ptr[si], 0
    jne show_menu_loop2
show_menu_p2:
    call print_line
    lea dx, menu_3
    mov ah, 09h
    int 21h
    popa
    ret
show_menu endp

print_cs proc
    push    ax
    push    dx
    mov     dx, cs
    and     dx, 0f000h
    shr     dx, 12
    call    print_hex
    mov     dx, cs
    and     dx, 0f00h
    shr     dx, 8
    call    print_hex
    mov     dx, cs
    and     dx, 00f0h
    shr     dx, 4
    call    print_hex
    mov     dx, cs
    and     dx, 000fh
    call    print_hex
    pop     dx
    pop     ax
    ret
print_cs endp

print_hex proc
    push    dx
    push    ax
    cmp     dx, 10
    jae     hex_10
    add     dx, 30h
    jmp     out_put
hex_10:
    add     dx, 37h
out_put:
    mov     ah, 02h
    int     21h
    pop     ax
    pop     dx
    ret
print_hex endp

TIMER	PROC
	PUSH  DX
	PUSH  CX
	PUSH  BX
	MOV   BX, AX
	MOV   AH, 2CH
	INT   21H	     ;CH=hour(0-23),CL=minute(0-59),DH=second(0-59),DL=centisecond(0-100)
	MOV   AL, DH
	MOV   AH, 0
	IMUL  AX,AX,1000
	MOV   DH, 0
	IMUL  DX,DX,10
	ADD   AX, DX
	CMP   BX, 0
	JNZ   _T1
	MOV   CS:_TS, AX
_T0:	POP   BX
	POP   CX
	POP   DX
	RET
_T1:	SUB   AX, CS:_TS
	JNC   _T2
	ADD   AX, 60000
_T2:	MOV   CX, 0
	MOV   BX, 10
_T3:	MOV   DX, 0
	DIV   BX
	PUSH  DX
	INC   CX
	CMP   AX, 0
	JNZ   _T3
	MOV   BX, 0
_T4:	POP   AX
	ADD   AL, '0'
	MOV   CS:_TMSG[BX], AL
	INC   BX
	LOOP  _T4
	PUSH  DS
	MOV   CS:_TMSG[BX+0], 0AH
	MOV   CS:_TMSG[BX+1], 0DH
	MOV   CS:_TMSG[BX+2], '$'
	LEA   DX, _TS+2
	PUSH  CS
	POP   DS
	MOV   AH, 9
	INT   21H
	POP   DS
	JMP   _T0
_TS	DW    ?
 	DB    'Time elapsed in ms is '
_TMSG	DB    12 DUP(0)
TIMER   ENDP

exit:
    mov     ah, 4ch
    int     21h
code ends
end start