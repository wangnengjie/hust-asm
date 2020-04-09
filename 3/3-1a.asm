public  null, auth, CRLF
extrn   curr_item: word
extrn   search_item: near, place_order: near, calc_all_rate: near, modify_item: near

print_line macro
    io      09h, <offset CRLF>
endm

io macro code, addr
    push    ax
    push    dx
    mov     dx, addr
    mov     ah, code
    int     21h
    pop     dx
    pop     ax
endm

putchar macro char
    push    ax
    push    dx
    mov     ah, 02h
    mov     dl, char
    int     21h
    pop     dx
    pop     ax
endm

.386
stack segment use16 stack
    db 500 dup(0)
stack ends

data segment use16 para public 'data'
    null            db  ?
    CRLF            db  13, 10, '$'
    auth            db  0
    shop_name       db  'shop', '$'
    customer        db  'customer', '$'
    boss_name       db  'wangnengjie', 0
    boss_pwd        db  '123456', 0

    in_username     db  15
                    db  0
                    db  15 dup(0)
    in_pwd          db  7
                    db  0
                    db  7 dup(0)

    username_hint   db  'Please enter your username: ', '$'
    pwd_hint        db  'Please enter your password: ', '$'

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
    login_succ_hint db  'Success login in', '$'
    next_step_hint  db  '(press any key to continue)', '$'
data ends

code segment use16 para public 'code'
    assume cs:code, ds:data, ss:stack

start:
    mov     ax, data
    mov     ds, ax
    jmp     entry_point

wait_for_check:
    print_line
    io      09h, <offset next_step_hint>
    mov     ah, 1
    int     21h
entry_point:
    print_line
    call    show_menu
    mov     ah, 1
    int     21h
    sub     al, 30h
    print_line
    cmp     al, 1
    je      func_1
    cmp     al, 2
    je      func_2
    cmp     al, 3
    je      func_3
    cmp     al, 4
    je      func_4
    cmp     al, 6
    je      func_6
    cmp     al, 8
    je      func_8
    cmp     al, 9
    je      exit
    jmp     entry_point
func_1:
    call    login
    jmp     wait_for_check
func_2:
    call    search_item
    jmp     wait_for_check
func_3:
    call    place_order
    jmp     wait_for_check
func_4:
    call    calc_all_rate
    jmp     entry_point
func_6:
    call    modify_item
    jmp     wait_for_check
func_8:
    call    print_cs
    jmp     wait_for_check

login proc
    pusha
login_entry:
    mov     auth, 0
    io      09h, <offset username_hint>
    io      0ah, <offset in_username>
    print_line
    cmp     in_username + 2, 13
    je      login_exit
    io      09h, <offset pwd_hint>
    io      0ah, <offset in_pwd>
    print_line
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
    io      09h, <offset login_succ_hint>
    jmp     login_exit
login_fail:
    io      09h, <offset login_fail_hint>
    print_line
    jmp     login_entry
login_exit:
    popa
    ret
login endp

show_menu proc
    pusha
    io      09h, <offset menu_1>
    cmp     auth, 1
    je      show_menu_bname
    io      09h, <offset customer>
    jmp     show_menu_p1
show_menu_bname:
    lea     si, boss_name
show_menu_loop1:
    putchar [si]
    inc     si
    cmp     byte ptr[si], 0
    jne     show_menu_loop1
show_menu_p1:
    print_line
    io      09h, <offset menu_2>
    cmp     curr_item, offset null
    je      show_menu_p2
    mov     si, curr_item
show_menu_loop2:
    putchar [si]
    inc     si
    cmp     byte ptr[si], 0
    jne     show_menu_loop2
show_menu_p2:
    print_line
    io      09h, <offset menu_3>
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
    putchar dl
    pop     ax
    pop     dx
    ret
print_hex endp

exit:
    mov     ah, 4ch
    int     21h
code ends
end start