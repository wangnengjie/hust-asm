.386
.model flat, stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc
include comctl32.inc

includelib windows.lib
includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib
includelib comctl32.lib

WinMain     proto :dword, :dword, :dword, :dword
WndProc     proto :dword, :dword, :dword, :dword
CalcRate    proto
PrintAll    proto :dword
Int16ToString   proto :word
StrLen      proto :dword
Sort        proto

Item struct
    itemName    db 10 dup(0)
    discount    dw 0
    inPrice     dw 0
    price       dw 0
    inNum       dw 0
    outNum      dw 0
    rate        dw 0
Item ends

.stack
.data
    H_INSTANCE      dd  0
    COMMAND_LINE    dd  0
    ClassName       db  'WindowsClass', 0
    AppName         db  'Store', 0
    AboutMsg        db  'Developed by WangNengJie', 0
    MAX_ITEM_AMOUNT equ 10
    itemsNumber     dd  5
    items           Item <'pen', 9, 9, 15, 100, 0, ?>
                    Item <'bag', 8, 35, 56, 50, 0, ?>
                    Item <'book', 9, 12, 30, 25, 5, ?>
                    Item <'computer', 7, 5000, 9000, 30, 4, ?>
                    Item <'eraser', 9, 3, 5, 100, 20, ?>
                    Item MAX_ITEM_AMOUNT - 5 dup(<'TempValue', 8, 15, 20, 30, 2, ?>)
    nameHint        db  'name', 0
    discount        db  'discount', 0
    inPrice         db  'inPrice', 0
    price           db  'price', 0
    inNum           db  'inNum', 0
    outNum          db  'outNum', 0
    rate            db  'rate', 0
    stringBuffer    db  10 dup(0)
    ; tempItem        Item <>

.code
start:
    invoke  GetModuleHandle, NULL
    mov     H_INSTANCE, eax
    invoke  GetCommandLine
    mov     COMMAND_LINE, eax
    invoke  WinMain, H_INSTANCE, NULL, COMMAND_LINE, SW_SHOWDEFAULT
    invoke  ExitProcess, eax

WinMain proc hInst: dword, hPrevInst: dword, CmdLine: dword, CmdShow: dword
    local   wc:WNDCLASSEX
    local   msg:MSG
    local   hwnd:HWND

    mov     wc.cbSize, sizeof WNDCLASSEX
    mov     wc.style, CS_HREDRAW or CS_VREDRAW
    mov     wc.lpfnWndProc, offset WndProc
    mov     wc.cbClsExtra, NULL
    mov     wc.cbWndExtra, NULL
    push    hInst
    pop     wc.hInstance
    mov     wc.hbrBackground, COLOR_WINDOW + 1
    mov     wc.lpszMenuName, NULL
    mov     wc.lpszClassName, offset ClassName
    invoke  LoadIcon, NULL, IDI_APPLICATION
    mov     wc.hIcon, eax
    mov     wc.hIconSm, 0
    invoke  LoadCursor, NULL, IDC_ARROW
    mov     wc.hCursor, eax
    invoke  RegisterClassEx, addr wc
    invoke  CreateWindowEx, NULL, addr ClassName, addr AppName, WS_OVERLAPPEDWINDOW + WS_VISIBLE, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, NULL, NULL, hInst, NULL
    mov     hwnd, eax
    invoke  LoadMenu, hInst, 600
    invoke  SetMenu, hwnd, eax
    ; invoke  ShowWindow, hwnd, SW_SHOWNORMAL
    ; invoke  UpdateWindow, hwnd
startLoop:
    invoke  GetMessage, addr msg, NULL, 0, 0
    cmp     eax, 0
    je      exitWinMain
    invoke  TranslateMessage, addr msg
    invoke  DispatchMessage, addr msg
    jmp     startLoop
exitWinMain:
    mov     eax, msg.wParam
    ret
WinMain endp

WndProc proc hWnd:dword, uMsg:dword, wParam:dword, lParam:dword
    local   hdc:HDC
    .if uMsg == WM_DESTROY
        invoke  PostQuitMessage, NULL
        ret
    .elseif uMsg == WM_COMMAND
        .if wParam == 1001
            invoke  SendMessage, hWnd, WM_CLOSE, 0, 0
        .elseif wParam == 2001
            invoke  CalcRate
        .elseif wParam == 2002
            invoke  CalcRate
            invoke  Sort
            invoke  PrintAll, hWnd
        .elseif wParam == 3001
            invoke  MessageBox, hWnd, addr AboutMsg, addr AppName, MB_OK
        .endif
    .else
        invoke  DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    .endif
    xor     eax, eax
    ret
WndProc endp

CalcRate proc
    pushad
    mov     ecx, itemsNumber
    lea     esi, items
calc_loop:
    movzx   eax, [esi].Item.price
    movzx   ebx, [esi].Item.discount
    mul     ebx
    mov     edi, eax

    movzx   eax, [esi].Item.inPrice
    mov     ebx, 1280
    mul     ebx
    div     edi
    mov     edi, eax

    movzx   eax, [esi].Item.outNum
    shl     eax, 6
    xor     edx, edx
    movzx   ebx, [esi].Item.inNum
    div     ebx

    add     eax, edi
    mov     [esi].Item.rate, ax

    add     esi, sizeof Item
    loop    calc_loop
    popad
    ret
CalcRate endp

PrintAll proc hWnd:dword
    local   hdc:HDC
    local   vertical:dword
    local   index:dword

    pushad
    mov     vertical, 50
    invoke  GetDC, hWnd
    mov     hdc, eax
    invoke  TextOut, hdc, 50, vertical, addr nameHint, 4
    invoke  TextOut, hdc, 150, vertical, addr discount, 8
    invoke  TextOut, hdc, 250, vertical, addr inPrice, 7
    invoke  TextOut, hdc, 350, vertical, addr price, 5
    invoke  TextOut, hdc, 450, vertical, addr inNum, 5
    invoke  TextOut, hdc, 550, vertical, addr outNum, 6
    invoke  TextOut, hdc, 650, vertical, addr rate, 4
    
    lea     esi, items
    mov     index, 0
print_loop:
    add     vertical, 50
    invoke  StrLen, addr [esi].Item.itemName
    invoke  TextOut, hdc, 50, vertical, addr [esi].Item.itemName, eax
    invoke  Int16ToString, [esi].Item.discount
    invoke  TextOut, hdc, 150, vertical, addr stringBuffer, eax
    invoke  Int16ToString, [esi].Item.inPrice
    invoke  TextOut, hdc, 250, vertical, addr stringBuffer, eax
    invoke  Int16ToString, [esi].Item.price
    invoke  TextOut, hdc, 350, vertical, addr stringBuffer, eax
    invoke  Int16ToString, [esi].Item.inNum
    invoke  TextOut, hdc, 450, vertical, addr stringBuffer, eax
    invoke  Int16ToString, [esi].Item.outNum
    invoke  TextOut, hdc, 550, vertical, addr stringBuffer, eax
    invoke  Int16ToString, [esi].Item.rate
    invoke  TextOut, hdc, 650, vertical, addr stringBuffer, eax
    add     esi, sizeof Item
    add     index, 1
    mov     eax, index
    cmp     eax, itemsNumber
    jne     print_loop
    popad
    ret
PrintAll endp

Int16ToString proc int16:word
    local   len:dword
    pushad
    lea     esi, stringBuffer
    mov     ecx, lengthof stringBuffer
reset_loop:
    mov     byte ptr[esi], 0
    inc     esi
    loop    reset_loop

    mov     ax, int16
    mov     bx, 10
    xor     ecx, ecx
    lea     esi, stringBuffer
its_loop:
    xor     dx, dx
    div     bx
    add     dl, '0'
    push    dx
    inc     cx
    cmp     ax, 0
    jne     its_loop
    mov     len, ecx
get_loop:
    pop     dx
    mov     byte ptr[esi], dl
    inc     esi
    loop    get_loop
    popad
    mov     eax, len
    ret
Int16ToString endp

StrLen proc stringAddr:dword
    push    esi
    xor     eax, eax
    mov     esi, stringAddr
StrLen_loop:
    cmp     byte ptr[esi], 0
    je      StrLen_exit
    inc     esi
    inc     eax
    jmp     StrLen_loop
StrLen_exit:
    pop     esi
    ret
StrLen endp

Sort proc
    local   tempItem:Item
    pushad
    mov     ecx, 1
sort_loop1:    
    imul    esi, ecx, sizeof Item
    mov     edi, esi
    
    xor     ebx, ebx
copy_loop1:
    mov     al, byte ptr items[esi+ebx]
    mov     byte ptr tempItem[ebx], al
    inc     ebx
    cmp     ebx, sizeof Item
    jne     copy_loop1

sort_loop2:
    sub     edi, sizeof Item
    mov     ax, tempItem.rate
    cmp     ax, items[edi].Item.rate
    jna     loop2_exit

    xor     ebx, ebx
copy_loop2:
    mov     al, byte ptr items[edi+ebx]
    mov     byte ptr items[esi+ebx], al
    inc     ebx
    cmp     ebx, sizeof Item
    jne     copy_loop2

    sub     esi, sizeof Item
    cmp     edi, 0
    jne     sort_loop2
loop2_exit:
    
    xor     ebx, ebx
copy_loop3:
    mov     al, byte ptr tempItem[ebx]
    mov     byte ptr items[esi+ebx], al
    inc     ebx
    cmp     ebx, sizeof Item
    jne     copy_loop3

    inc     ecx
    cmp     ecx, itemsNumber
    jbe     sort_loop1
    popad
    ret
Sort endp
end start
