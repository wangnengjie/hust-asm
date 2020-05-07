.386
.model flat, C

.data
    username_hint   db  'Please enter your username(q to exit): ', 0
    pwd_hint        db  'Please enter your password: ', 0
    CRLF            db  13, 10, 0
    stringfmt       db  '%s', 0
    intfmt          db  '%d', 0
    shortfmt        db  '%hu', 0
    in_username     db  20 dup(0)
    in_pwd          db  10 dup(0)
    login_fail_hint db  'Login failed!', 0
    login_succ_hint db  'Success log in!', 0
    in_item         db  10 dup(0)
    in_number       dw  ?
    arrow           db  ' ==> ', 0
    item_name_hint  db  'Please enter the name of item: ', 0
    ; found_hint      db  'Item found!', 0
    not_found_hint  db  'Item not found!', 0
    order_make_hint db  'Success place order!', 0
    order_err_hint  db  'Fail to place order!', 0
    err_item_hint   db  'Please choose an item!', 0
    modify_succ     db  'Success!', 0
    
    item_dtl_1      db  'item name: ', 0
    item_dtl_2      db  'item discount: ', 0
    item_dtl_3      db  'purchase price: ', 0
    item_dtl_4      db  'sell price: ', 0
    item_dtl_5      db  'purchase volume: ', 0
    item_dtl_6      db  'quantity sold: ', 0
    item_dtl_7      db  'rate: ', 0

.code
public login
public search_item
public print_cs
extrn boss_name:dword
extrn boss_pwd:dword
extrn items:byte
extrn max_items:dword

login proto C, authAddr:dword
search_item proto C
place_order proto C, itemAddr:dword
modify_item proto C, itemAddr:dword
print_cs proto C

putchar proto C, char:byte
printf proto C:ptr sbyte,:vararg
scanf proto C:ptr sbyte,:vararg
calc_rate proto C, itemAddr:dword

login proc authAddr:dword
    pushad
login_entry:
    mov     eax, authAddr
    mov     dword ptr [eax], 0
    invoke  printf, addr username_hint
    invoke  scanf, addr stringfmt, addr in_username
    cmp     in_username, 'q'
    je      login_exit
    invoke  printf, addr pwd_hint
    invoke  scanf, addr stringfmt, addr in_pwd
verify_username:
    lea     ebx, in_username
    mov     esi, boss_name
verify_username_check_loop:
    mov     al, [ebx]
    cmp     byte ptr[esi], al
    jne     login_fail
    inc     esi
    inc     ebx
    cmp     byte ptr[esi], 0
    jne     verify_username_check_loop
    cmp     byte ptr[ebx], 0
    jne     verify_username_check_loop
    jmp     verify_pwd
verify_pwd:
    lea     ebx, in_pwd
    mov     esi, boss_pwd
verify_pwd_check_loop:
    mov     al, [ebx]
    cmp     byte ptr[esi], al
    jne     login_fail
    inc     esi
    inc     ebx
    cmp     byte ptr[esi], 0
    jne     verify_pwd_check_loop
    cmp     byte ptr[ebx], 0
    jne     verify_pwd_check_loop
    mov     eax, authAddr
    mov     dword ptr [eax], 1
    invoke  printf, addr login_succ_hint
    invoke  printf, addr CRLF
    jmp     login_exit
login_fail:
    invoke  printf, addr login_fail_hint
    invoke  printf, addr CRLF
    jmp     login_entry
login_exit:
    popad
    ret
login endp

search_item proc
    local   curr_item:dword
    local   flag:byte
    mov     flag, 0
    pushad
    invoke  printf, addr item_name_hint
    invoke  scanf, addr stringfmt, addr in_item
    
    lea     edx, items
    mov     ecx, max_items
item_loop:
    mov     ebx, edx
    lea     esi, in_item
check_item:
    mov     al, [ebx]
    cmp     byte ptr[esi], al
    jne     next_item
    inc     ebx
    inc     esi
    cmp     byte ptr[esi], 0
    jne     check_item
    cmp     byte ptr[ebx], 0
    jne     check_item
    jmp     item_found
next_item:
    add     edx, 22
    loop    item_loop
    jmp     item_not_found
item_not_found:
    invoke  printf, addr not_found_hint
    invoke  printf, addr CRLF
    jmp     search_item_exit
item_found:
    mov     curr_item, edx
    mov     flag, 1
    invoke  printf, addr item_dtl_1
    invoke  printf, curr_item
    invoke  printf, addr CRLF
    mov     esi, curr_item
    invoke  printf, addr item_dtl_2
    invoke  printf, addr shortfmt, word ptr 10[esi]
    invoke  printf, addr CRLF
    invoke  printf, addr item_dtl_4
    invoke  printf, addr shortfmt, word ptr 14[esi]
    invoke  printf, addr CRLF
    invoke  printf, addr item_dtl_5
    invoke  printf, addr shortfmt, word ptr 16[esi]
    invoke  printf, addr CRLF
    invoke  printf, addr item_dtl_6
    invoke  printf, addr shortfmt, word ptr 18[esi]
    invoke  printf, addr CRLF
    invoke  printf, addr item_dtl_7
    invoke  printf, addr shortfmt, word ptr 20[esi]
    invoke  printf, addr CRLF
search_item_exit:    
    popad
    cmp     flag, 1
    jne     search_item_return
    mov     eax, curr_item
search_item_return:
    ret
search_item endp

place_order proc itemAddr:dword
    pushad
    mov     ebx, itemAddr
    mov     ax, 15[ebx]
    cmp     ax, 18[ebx]
    je      place_order_err
    inc     word ptr 18[ebx]
    invoke  printf, addr order_make_hint
    invoke  calc_rate, itemAddr
    jmp     place_order_exit
place_order_err:
    invoke  printf, addr order_err_hint
    invoke  printf, addr CRLF
place_order_exit:
    popad
    ret
place_order endp

modify_item proc itemAddr:dword
    pushad
set_discount:
    mov     esi, itemAddr
    invoke  printf, addr item_dtl_2
    invoke  printf, addr shortfmt, word ptr 10[esi]
    invoke  printf, addr arrow
    invoke  scanf, addr shortfmt, addr in_number
    cmp     eax, 0
    je      set_discount
    cmp     in_number, 10
    ja      set_discount
    cmp     in_number, 0
    jbe     set_discount
    mov     dx, in_number
    mov     10[esi], dx
set_in_price:
    invoke  printf, addr CRLF
    invoke  printf, addr item_dtl_3
    invoke  printf, addr shortfmt, word ptr 12[esi]
    invoke  printf, addr arrow
    invoke  scanf, addr shortfmt, addr in_number
    cmp     eax, 0
    je      set_in_price
    mov     dx, in_number
    mov     12[esi], dx
set_sell_price:
    invoke  printf, addr CRLF
    invoke  printf, addr item_dtl_4
    invoke  printf, addr shortfmt, word ptr 14[esi]
    invoke  printf, addr arrow
    invoke  scanf, addr shortfmt, addr in_number
    cmp     eax, 0
    je      set_sell_price
    mov     dx, in_number
    mov     14[esi], dx
set_in_amount:
    invoke  printf, addr CRLF
    invoke  printf, addr item_dtl_5
    invoke  printf, addr shortfmt, word ptr 16[esi]
    invoke  printf, addr arrow
    invoke  scanf, addr shortfmt, addr in_number
    cmp     eax, 0
    je      set_in_amount
    mov     dx, in_number
    mov     16[esi], dx
    invoke  calc_rate, itemAddr
    invoke  printf, addr modify_succ
    popad
    ret
modify_item endp

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
    cmp     dx, 10
    jae     hex_10
    add     dx, 30h
    jmp     out_put
hex_10:
    add     dx, 37h
out_put:
    invoke  putchar, dl
    ret
print_hex endp

end