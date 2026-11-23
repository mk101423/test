

// Make constant prices for the items that are in the shop, so that we can use them in the shop_item.asm file. This will allow us to have a consistent price for the items that are in the shop, and we can change the prices in one place if we want to change them later on. The shop items occupy 1 bits of memory, so we can use 1 byte for the price of the items. We can use 1 byte since we only need to store up to 255 currency, which is more than enough for our game.
section .data:
    // Price of the shop items. This will be used to determine the cost of each item in the shop.
     ITEM_HEALTH_POTION_PRICE: .equ 10
     ITEM_DAMAGE_POTION_PRICE: .equ 20
     ITEM_KENTRO_SWORD_PRICE: .equ 50
     ITEM_KOPIS_SWORD_PRICE: .equ 75
     ITEM_HELMET_PRICE: .equ 30
     ITEM_AEGIS_SHIELD_PRICE: .equ 40
     ITEM_ARMOR_PRICE: .equ 100
     shop_items_array: .word ITEM_HEALTH_POTION_PRICE, ITEM_DAMAGE_POTION_PRICE, ITEM_KENTRO_SWORD_PRICE, ITEM_KOPIS_SWORD_PRICE, ITEM_HELMET_PRICE, ITEM_AEGIS_SHIELD_PRICE, ITEM_ARMOR_PRICE


    
.section .bss
    .align 4
    // We only need 4 * 3 bytes for the shop items picked since we only have 3 items in the shop
    shop_items_picked: .skip 12


.text
.global start
.global purchase_item

.extern grab_user_currency_data
.extern transaction_success_currency


start:

// Apparently we can use C-library, this would of saved so much time for shuffling. We'll use rand and srand to  generate integers and distinct random numbers for shuffling the shop items.
.extern rand

purchase_item:
    // This function will handle the purchase of an item from the shop. So if we want to, we can have a interactive system that randomizes the items available for purchase each time the player visits the shop. We want to setup like a randomize item shop for more dynamic, so everytime the user closes and reopens the shop, the items available for purchase will be different. We can grab the atomicity_transaction.asm since it's a global function and we can call it anywhere. We're gonna use this to interact with the shop terminal UI. Let x19 be the currency function, and then x20 be the selected item for the shop, and then we use the transaction function to handle the purchase accordingly.
    mov x19, x0
    bl grab_user_currency_data
    mov x19, x0
    mov x20, x1
    bl transaction_success_currency
    // After calling transaction_success_currency, we can check the result in the transaction state variables to determine if the purchase was successful or not. If the transaction was successful, we can proceed with updating the user's inventory and deducting the currency. If the transaction failed, we can handle it accordingly, such as displaying an error message to the user.
    ldr x0, =transaction_success




    


sort_shop_items_random:
    // Grab the initialized array of shop items and randomize their order for the shop display. This will allow the shop to present different items each time it is accessed, making the shop dynamic and more engaging for the player. We'll use the rand shuffling
    // Load the address of x19 with the array of shop items and x20 with the array of picked shop items
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    ldr x19, =shop_items_array
    ldr x20, =shop_items_picked
    // Then we grab the last element of the array to use it in the shuffling process. This will help us swap elements and randomize the order of the shop items effectively. We only need 32-bit as we're dealing with 32-bit prices.
    mov w20, #0
    mov w21, #0

loo:
    // This is a randomized loop system that will iterate through the shop items array and swap elements to shuffle the order randomly. We need three items as we only have 3 items in the shop. Perhaps after the project is done, we can extend it towards probability of shop appearing
    bl rand
    // Assuming 7 items, each 4 bytes, last element offset is 7*4=28
    add w9, w19, #28  
    // Calculate the remainder of the division to get a random index within the range of the array (0 to 6). This ensures the random index is valid for the shop items array.
    udiv w10, w0, w9
    msub w11, w10, w9, w0
    // Calculate the address of the randomly selected item in the shop items array. The result will be stored in w2
    add w2, w19, w0, lsl #2
    ldr w3, [w2]
    // Swap the randomly selected item with the last element in the array
    add w4, w19, w20, lsl #2
    ldr w5, [w4]
    str w3, [w4]
    str w5, [w2]
    











