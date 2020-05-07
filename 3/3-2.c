#define MAX_ITEMS 10
#define BY_ASM
#include <stdio.h>
#include <stdlib.h>

extern _CRT_STDIO_INLINE int __CRTDECL scanf(
    _In_z_ _Scanf_format_string_ char const *const _Format,
    ...);

typedef struct Item
{
    char name[10];
    unsigned short discount;
    unsigned short inPrice;
    unsigned short price;
    unsigned short inNum;
    unsigned short outNum;
    unsigned short rate;
} Item;

Item items[MAX_ITEMS] = {
    {"bag", 8, 35, 56, 50, 0, 0},
    {"book", 9, 12, 30, 25, 5, 0},
    {"temp", 8, 15, 20, 30, 2, 0},
    {"temp", 8, 15, 20, 30, 2, 0},
    {"temp", 8, 15, 20, 30, 2, 0},
    {"temp", 8, 15, 20, 30, 2, 0},
    {"temp", 8, 15, 20, 30, 2, 0},
    {"temp", 8, 15, 20, 30, 2, 0},
    {"temp", 8, 15, 20, 30, 2, 0},
    {"temp", 8, 15, 20, 30, 2, 0}};

const char *boss_name = "wangnengjie";
const char *boss_pwd = "123456";
const int max_items = MAX_ITEMS;

void printMenu(int, Item *);
void login(int *);
Item *search_item();
void place_order(Item *);
void calc_rate(Item *);
void modify_item(Item *);
void print_cs();

int main(void)
{
    int auth = 0;
    char option = 0;
    Item *currentItem = NULL;
    while (option != '9')
    {
        printMenu(auth, currentItem);
        option = getchar();
        switch (option)
        {
        case '1':
        {
            login(&auth);
            break;
        }
        case '2':
        {
            currentItem = search_item();
            break;
        }
        case '3':
        {
            if (currentItem != NULL)
            {
                place_order(currentItem);
            }
            else
            {
                printf("Fail to place order!\n");
            }
            break;
        }
        case '4':
        {
            for (size_t i = 0; i < MAX_ITEMS; i++)
            {
                calc_rate(items + i);
            }
            break;
        }
        case '6':
        {
            if (!auth)
            {
                printf("Please log in as boss!\n");
                break;
            }
            if (currentItem == NULL)
            {
                printf("Please choose an item!\n");
                break;
            }
            modify_item(currentItem);
            break;
        }
        case '8':
        {
            print_cs();
            printf("\n");
            break;
        }
        case '9':
            return 0;
        default:
            break;
        }
        while (getchar() != '\n')
            ;
        getchar();
    }
    return 0;
}

void printMenu(int auth, Item *curr)
{
    printf("User: %s\n", auth == 0 ? "customer" : boss_name);
    printf("Current Item: %s\n", curr == NULL ? "" : curr->name);
    printf("1. Log in\n"
           "2. Search item\n"
           "3. Place an order\n"
           "4. Calculate suggestion rate\n"
           "5. Calculate suggestion rank\n"
           "6. Modify item\n"
           "7. Migrate runtime\n"
           "8. Show head address of code segment\n"
           "9. Exit\n");
}

void calc_rate(Item *item)
{
#ifndef BY_ASM
    item->rate = (short)((item->inPrice / (((double)item->price * item->discount) / 10.0) + item->outNum / (2.0 * item->inNum)) * 128);
#else
    __asm {
		mov     esi, item
		movzx   eax, word ptr 14[esi]
		movzx   ebx, byte ptr 10[esi]
		mul     ebx
		mov     ecx, eax

		movzx   eax, word ptr 12[esi]
		mov     ebx, 1280
		mul     ebx
		div     ecx
		mov     ecx, eax

		movzx   eax, word ptr 18[esi]
		shl     eax, 6; *64
		xor edx, edx
		movzx   ebx, word ptr 16[esi]
		div     ebx

		add     eax, ecx
		mov     20[esi], ax
    }
#endif // !ASM
}