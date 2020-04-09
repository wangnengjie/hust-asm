; author: wnj
; proc: search_item, place_order
public  max_item, curr_item, item_1
public  search_item, place_order, modify_item
extrn   null: byte, auth: byte, CRLF: byte
extrn   calc_all_rate: near, print_number: near, stoi16: near

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
    N               equ 10
    max_item        dw  N
    curr_item       dw  null
    ; dw    in_price, sell_price, in_amount, sell_amount, rate
    item_1          db  'bag', 7 dup(0), 8
                    dw  35, 56, 50, 0, ?
    item_2          db  'book', 6 dup(0), 9
                    dw  12, 30, 25, 5, ?
    item_temp       db  N - 2 dup('TempValue', 0, 8, 15, 0, 20, 0, 30, 0, 2, 0, ?, ?)
    
    in_item         db  10
                    db  0
                    db  10 dup(0)
    
    in_number       db  6
                    db  0
                    db  6  dup(0)

    arrow           db  ' ==> ', '$'
    item_name_hint  db  'Please enter the name of item: ', '$'
    ; found_hint      db  'Item found!', '$'
    not_found_hint  db  'Item not found!', '$'
    order_make_hint db  'Success place order!', '$'
    order_err_hint  db  'Fail to place order!', '$'
    err_item_hint   db  'Please choose an item!', '$'
    
    item_dtl_1      db  'item name: ', '$'
    item_dtl_2      db  'item discount: ', '$'
    item_dtl_3      db  'purchase price: ', '$'
    item_dtl_4      db  'sell price: ', '$'
    item_dtl_5      db  'purchase volume: ', '$'
    item_dtl_6      db  'quantity sold: ', '$'
    item_dtl_7      db  'rate: ', '$'
data ends

code segment use16 para public 'code'
    assume cs:code, ds:data, ss:stack

search_item proc
    pusha
    io      09h, <offset item_name_hint>
    io      0ah, <offset in_item>
    print_line
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
    io      09h, <offset not_found_hint>
    print_line
    jmp     search_item_exit
item_found:
    mov     curr_item, dx
    ; io      09h, <offset found_hint>
    io      09h, <offset item_dtl_1>
    mov     si, curr_item
item_name_loop:
    mov     al, [si]
    putchar al
    inc     si
    cmp     byte ptr [si], 0
    jne     item_name_loop
    print_line
    mov     si, curr_item
    io      09h, <offset item_dtl_2>
    movzx   ax, byte ptr 10[si]
    call    print_number
    print_line
    io      09h, <offset item_dtl_4>
    mov     ax, 13[si]
    call    print_number
    print_line
    io      09h, <offset item_dtl_5>
    mov     ax, 15[si]
    call    print_number
    print_line
    io      09h, <offset item_dtl_6>
    mov     ax, 17[si]
    call    print_number
    print_line
    io      09h, <offset item_dtl_7>
    mov     ax, 19[si]
    call    print_number
    print_line
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
    inc     word ptr 17[bx]
    io      09h, <offset order_make_hint>
    call    calc_all_rate
    jmp     place_order_exit
place_order_err:
    io      09h, <offset order_err_hint>
    print_line
place_order_exit:
    popa
    ret
place_order endp

modify_item proc
    pusha
    cmp     curr_item, offset null
    jne     set_discount
err_item:
    io      09h, <offset err_item_hint>
    print_line
    jmp     modify_item_exit
set_discount:
    print_line
    mov     si, curr_item
    io      09h, <offset item_dtl_2>
    movzx   ax, byte ptr 10[si]
    call    print_number
    io      09h, <offset arrow>
    io      0ah, <offset in_number>
    cmp     in_number + 2, 13
    je      set_in_price
    lea     bx, in_number + 2
    call    stoi16
    cmp     dx, 0
    je      set_discount
    cmp     ax, 10
    ja      set_discount
    cmp     ax, 0
    jbe     set_discount
    mov     10[si], al
set_in_price:
    print_line
    io      09h, <offset item_dtl_3>
    mov     ax, 11[si]
    call    print_number
    io      09h, <offset arrow>
    io      0ah, <offset in_number>
    cmp     in_number + 2, 13
    je      set_sell_price
    lea     bx, in_number + 2
    call    stoi16
    cmp     dx, 0
    je      set_in_price
    mov     11[si], ax
set_sell_price:
    print_line
    io      09h, <offset item_dtl_4>
    mov     ax, 13[si]
    call    print_number
    io      09h, <offset arrow>
    io      0ah, <offset in_number>
    cmp     in_number + 2, 13
    je      set_in_amount
    lea     bx, in_number + 2
    call    stoi16
    cmp     dx, 0
    je      set_sell_price
    mov     13[si], ax
set_in_amount:
    print_line
    io      09h, <offset item_dtl_5>
    mov     ax, 15[si]
    call    print_number
    io      09h, <offset arrow>
    io      0ah, <offset in_number>
    cmp     in_number + 2, 13
    je      modify_item_exit
    lea     bx, in_number + 2
    call    stoi16
    cmp     dx, 0
    je      set_in_amount
    mov     15[si], ax
modify_item_exit:
    popa
    ret
modify_item endp

code ends
end