public  null, auth, CRLF, key
extrn   curr_item: word
extrn   search_item: near, place_order: near, calc_all_rate: near, modify_item: near, print_number: near

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

get_clock macro index
    mov     al, index
    out     70h, al
    jmp     $+2
    in      al, 71h
endm

.386
stack segment use16 stack
    db 500 dup(0)
stack ends

data segment use16 para public 'data'
    null            db  ?
    CRLF            db  13, 10, '$'
    auth            dw  0
    shop_name       db  'shop', '$'
    customer        db  'customer', '$'
    boss_name       db  'wangnengjie', 0
    boss_pwd        db  ('f' + 16h) xor 10100100b
                    db  ('x' + 16h) xor 10100100b
                    db  ('x' + 16h) xor 10100100b
                    db  ('k' + 16h) xor 10100100b
                    db  0
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
                    db  '8. Show head address of stack segment', 13, 10
                    db  '9. Exit', 13, 10, '$'
    key             dw  5c6eh, ?
    login_fail_hint db  'Login failed!', '$'
    login_succ_hint db  'Success login in', '$'
    next_step_hint  db  '(press any key to continue)', '$'
    old_1           dw  ?, ?
    old_3           dw  ?, ?
data ends

stackbak segment use16 para public 'stackbak'
    db 1500 dup(0)
stackbak ends

code segment use16 para public 'code'
    assume cs:code, ds:data, ss:stack
    target          db  0 ; 0: next to stackbak 1: next to stack
    has_set         db  0
    old_int         dw  ?, ?
    prev_min        db  ?
start:
    mov     ax, data
    mov     ds, ax
    xor     ax, ax
    mov     es, ax
    mov     ax, es:[1h*4]
    mov     old_1, ax
    mov     ax, es:[1h*4+2]
    mov     old_1 + 2, ax
    mov     ax, es:[3h*4]
    mov     old_3, ax
    mov     ax, es:[3h*4+2]
    mov     old_3 + 2, ax
    CLI
    mov     ax, new_1_3
    mov     es:[1h*4], ax
    mov     es:[1h*4+2], cs
    mov     es:[3h*4], ax
    mov     es:[3h*4+2], cs
    STI
    jmp     entry_point

new_1_3:
    iret

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
    cmp     al, 7
    je      func_7
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
func_7:
    call    migrate_runtime
    jmp     entry_point
func_8:
    call    print_ss
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
    CLI
    push    verify_pwd
    pop     bx
    mov     ax, [esp-2]
    STI
    jmp     ax
verify_pwd:
    CLI
    mov     ah, 2ch
    int     21h
    push    dx
    mov     key+2, dx
    lea     bx, in_pwd + 2
    lea     si, boss_pwd
    mov     ah, 2ch
    int     21h
    STI
    cmp     dx, [esp]
    pop     ax
    jne     login_fail
verify_pwd_check_loop:
    mov     al, [bx]
    add     al, 16h
    xor     al, 10100100b
    cmp     byte ptr[si], al
    jne     login_fail
    inc     si
    inc     bx
    cmp     byte ptr[si], 0
    jne     verify_pwd_check_loop
    cmp     byte ptr[bx], 13
    jne     verify_pwd_check_loop
    mov     ax, key
    xor     ax, key+2
    mov     auth, ax
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
    mov     ax, key
    xor     ax, key+2
    cmp     auth, ax
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

migrate_runtime proc
    push    ds
    push    ax
    cmp     cs:has_set, 0
    jne     migrate_runtime_exit
set_new:
    xor     ax, ax
    mov     ds, ax
    mov     ax, ds:[8h*4]
    mov     cs:old_int, ax
    mov     ax, ds:[8h*4+2]
    mov     cs:old_int+2, ax
    CLI
    mov     ds:[8h*4], new_int8
    mov     ds:[8h*4+2], cs
    STI
    mov     cs:has_set, 1
migrate_runtime_exit:
    pop     ax
    pop     ds
    ret
migrate_runtime endp

new_int8 proc
    pushf
    call    dword ptr cs:old_int

    pusha
    push    ds
    get_clock 2
    cmp     cs:prev_min, al
    je      new_int8_exit
    mov     bl, al
    get_clock 0
    cmp     al, 00110000b ; 8421code => 30s
    jne     new_int8_exit

    mov     bp, 1500
    mov     cs:prev_min, bl
    cmp     cs:target, 0
    jne     target_stack
    mov     ax, stackbak
    mov     ds, ax
    jmp     move
target_stack:
    mov     ax, stack
    mov     ds, ax
move:
    ; ds is now next stack seg, bx point to bottom
    mov     ax, ss:[bp]
    mov     ds:[bp], ax
    sub     bp, 2
    cmp     bp, sp
    jge     move
    cmp     cs:target, 0
    je      change_to_bak
    mov     ax, stack
    jmp     change_ss
change_to_bak:
    mov     ax, stackbak
change_ss:
    mov     ss, ax
    xor     cs:target, 1 ; 0 => 1 1 => 0
new_int8_exit:
    pop     ds
    popa
    iret
new_int8 endp

print_ss proc
    push    dx
    mov     dx, ss
    and     dx, 0f000h
    shr     dx, 12
    call    print_hex
    mov     dx, ss
    and     dx, 0f00h
    shr     dx, 8
    call    print_hex
    mov     dx, ss
    and     dx, 00f0h
    shr     dx, 4
    call    print_hex
    mov     dx, ss
    and     dx, 000fh
    call    print_hex
    pop     dx
    ret
print_ss endp

print_hex proc
    push    dx
    cmp     dx, 10
    jae     hex_10
    add     dx, 30h
    jmp     out_put
hex_10:
    add     dx, 37h
out_put:
    putchar dl
    pop     dx
    ret
print_hex endp

exit:
    cmp     cs:has_set, 0
    je      exit_point
    xor     ax, ax
    mov     ds, ax
    CLI
    mov     ax, cs:old_int
    mov     ds:[8h*4], ax
    mov     ax, cs:old_int + 2
    mov     ds:[8h*4+2], ax
    STI
    CLI
    mov  ax, old_1
    mov  ds:[1h*4], ax
    mov  ax, old_1 + 2
    mov  ds:[1h*4+2], ax
    mov  ax, old_3
    mov  ds:[3h*4], ax
    mov  ax, old_3 + 2
    mov  ds:[3h*4+2], ax 
    STI
exit_point:
    mov     ah, 4ch
    int     21h
code ends
end start