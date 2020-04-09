; author: wnj
; proc: calc_all_rate, calc_rate, print_number, stoi16
public  calc_all_rate, calc_rate, print_number, stoi16
extrn   item_1: byte, max_item: word

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
    int16   dw  0
data ends

code segment use16 para public 'code'
    assume cs:code, ds:data, ss:stack

calc_all_rate proc
    pusha
    mov     cx, max_item
    jcxz    calc_rate_exit
    lea     ax, item_1
calc_rate_loop:
    call    calc_rate
    add     ax, 21
    loop    calc_rate_loop
calc_rate_exit:
    popa
    ret
calc_all_rate endp

calc_rate proc
    pushad
    mov     si, ax
    movzx   eax, word ptr 13[si]
    movzx   ebx, byte ptr 10[si]
    mul     ebx
    mov     ecx, eax

    movzx   eax, word ptr 11[si]
    mov     ebx, 1280               ; 经测试，直接*1280比位运算2^10+2^8更快
    mul     ebx
    div     ecx
    mov     ecx, eax

    movzx   eax, word ptr 17[si]
    shl     eax, 6 ; *64
    xor     edx, edx
    movzx   ebx, word ptr 15[si]
    div     ebx

    add     eax, ecx
    mov     19[si], ax
    popad
    ret
calc_rate endp

print_number proc
    pusha
    mov     bx, 10
    mov     cx, 0
loop_divide_number:
    xor     dx, dx
    div     bx
    add     dl, '0'
    push    dx
    inc     cx
    cmp     ax, 0
    jne     loop_divide_number
loop_print_number:
    pop     dx
    putchar dl
    loop    loop_print_number
    popa
    ret
print_number endp

stoi16 proc
    pushad
    movzx   cx, byte ptr -1[bx]
    xor     eax, eax
    xor     edx, edx
stoi16_loop:
    mov     dl, [bx]
    cmp     dl, '9'
    ja      invalid
    cmp     dl, '0'
    jb      invalid
    sub     dl, 30h
    imul    eax, 10
    add     eax, edx
    inc     bx
    loop    stoi16_loop
    cmp     eax, 0ffffh
    ja      invalid
    mov     int16, ax
    popad
    mov     dx, 1
    mov     ax, int16
    ret
invalid:
    popad
    mov     dx, 0
    ret
stoi16 endp

code ends
end