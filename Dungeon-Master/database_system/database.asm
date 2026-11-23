// Primarily handling the database operations that allows to save for players data and load it back when needed. This is a simple implementation of a database that uses a file to store the data. The database is implemented as a simple key-value store, where the key is the player's name and the value is the player's data.


.section .text
section .rodata:
    // We want to hold all of the error messsages such as insufficent funds. We want this to be a rodata as it's a read-only section of memory. and constant strings
    global currency_insufficent
    global transaction_failed

    currency_insufficent: .ascii "Error: Insufficient funds\n"
    currency_insufficent_len = . - currency_insufficent

    transaction_failed_len = . - transaction_failed
    transaction_failed: .ascii "Error: Transaction failed\n"

    insufficent_sp: .ascii "Error: Insufficient SP\n"
    sufficent_sp_len = . - sufficent_sp








section .data:
    // This is where we will store the player's data in memory, such as health, damage, and status. Each player's attribute will occupy the number of bytes specified in the constants defined above. 
    // Player health, and boosting factors for health. We use player_current_health to check their current health with the respect of their maximum health (player_health)
    player_health: .word 2
    player_current_health: .word 2
    player_health_boost: .word 0.1
   
   // Player damage, and boosting factors for damage. We use player_current_damage to check their current damage with the respect of their maximum damage (player_damage)
    player_damage: .word 2
    player_current_damage: .word 2
    // 0. No Affect, 1. Poisoned, 2. Paralysed, 3. Burned, 4. Frozen
    player_status: .word 0
    // Depending on the item equipped, the player's damage may receive a boost. This is represented by player_damage_boost.
    damage_boost: .word 0.1



    // XP progress: Player_level, current_xp_gained, player_xp, xp_needed_to_level_up, bonus_xp (Depending on condition when fighting dungeons)
    player_current_xp_gained: .word 0
    player_xp: .word 2
    player_level: .word 2
    player_needed: .word 100
    player_sp: .word 0




    // Currency: Player's current amount of in-game currency. I wanna add a boost to the currency based on certain conditions, such as bonuses or multipliers.
    player_currency: .word 2
    player_curr_boost: .word 0.25



    // Enemy data. We're gonna store the Current health, damage, and status of the enemy, similar to the player's data. But we don't need currency because well they're not a player. We're creating a reduction based on the enemy's attributes to the respect of their level. If the enemy status is 0 there is no effect, if it's 1 that represents poisoned so that means damage will be done, and then call the poison affect on the boss or the individual character.
    enemy_health: .word 100
    enemy_damage: .word 1
    level_boost: .word 0.1
    check_enemy_status: .word 0
    
    // Boss Data: Similar to enemy data, but for the boss character. We'll store the boss's health, damage, and any level-based boosts. We want to have speciifc boss, so name them too. I wanna also create like a special type that each boss has, it will just be .set since we don't need it to be dynamic unlike the enemy_data. Level one boss will have a level recommend of 5. Make sure it's word as we're still dealing damage 
    boss_aegis_health: .word 500
    boss_aegis_damage: .word 10
    boss_aegis_level_boost: .word 0.2
    boss_aegis_type: .set 1
    boss_aegis_level_rec: .set 5
    boss_aegis_status: .word 0




.global print_currency_insufficent
.global print_transaction_failed

.global xp_gained
.global grab_user_currency_data
.extern dungeon_is_room_cleared
.extern xp_level_needed



.global xp_progress_bar
.global sufficent_sp
.global grab_player_data

grab_player_data:
    // We want to use callee register for storing the player's data across function calls. Let x19 hold the player's health, x20 hold the player's damage, and x21 hold the player's level. Kidduz will interact it via grab_player_data[i] where i corresponds to the index of the data (0 for health, 1 for damage, 2 for level).
    // Load the addresses of the player's health, damage, and level into the respective callee registers. This allows other functions to access and modify the player's data consistently. And then use 32-bit loads and stores to interact with the actual values.
    ldr x9, =player_health
    ldr w19, [x9]
    // Bring the pointer to the address of player_damage into x9 and then load the value into w20.
    ldr x9, =player_damage
    ldr w20, [x9]
    // Bring the pointer to the address of player_level into x9 and then load the value into w21.
    ldr x9, =player_level
    ldr w21, [x9]
    // I forgot to mention that we should also load the player's current level to make sure the xp_system function of xp_level_needed gets the necssary information, let w22 be the player's current level.
    ldr x9, =player_level
    ldr w22, [x9]
    ldr x9, =player_xp
    ldr w23, [x9]

    // This will be in x30 as the return address after the function call. So kidduz needs to use stp x29, x30 to save the return address if needed before making another function call and then restore it with ldp x29, x30 before returning.
    ret

xp_progress_bar: 
    // We want to also display the player's progress towards the next level in the XP bar. This will involve fetching the current XP and the XP needed for the next level, then calculating the percentage of progress. We want to also grab the xp progress calculation by current xp / xp needed for the next level and display accordingly. Let x24 hold player xp and x25 hold player needed xp. The formula for progress will be: (x24 * 100) / x25 to get the percentage of XP progress. let x26 be the base 100. Oh and we can use unsigned divison as we're not likely to hold negative values for XP. We'll use the pointer of x9 register to point to the address of player_xp and then load the x24 value from it, and so on.
    // Load the xp_level_needed address into w25.
    bl xp_level_needed
    ldr w25, x20
    mov w26, #100
    ldr x9, =player_xp
    ldr w23, [x9]
    mul w23, w23, w26
    udiv w23, w23, w25
    ret

grab_user_currency_data:
    // Load the currency and make sure it's callee register to save the value across function calls. This ensures that the player's currency is correctly retrieved and preserved. Let x19 be the register to hold the player's currency value.
    ldr x9, =player_currency
    ldr x19, [x9]
    ret



xp_gained:
    // This is a helper function to update the player's XP gained after clearing a room. So this is conencting to the game_state.asm file that has the function dungeon_is_room_cleared. If the room is cleared, we will add the XP gained from the room to the player's current XP.
    // Let x24 hold the current XP of the player and x25 hold the XP gained from the room. We will then update the player's XP in the database.
    //
    ldr x9, =player_xp
    ldr x24, [x9]
    ldr x9, =room_xp_gain
    ldr x25, [x9]
    add x24, x24, x25
    ldr x9, =player_xp
    str x24, [x9]
    ret




print_currency_insufficent:
    // First register holds the file descriptor for stdout (0 for standard output)
    mov x0, #0
    // Call the address of the currency_insufficent error message
    adr x1, currency_insufficent
    mov x2, #currency_insufficent_len
    mov x8, #64  // syscall number for write
    svc #0
    ret

print_transaction_failed:
    mov x0, #0
    // Call the address of the transaction_failed error message
    adr x1, transaction_failed
    mov x2, #transaction_failed_len
    mov x8, #64  // syscall number for write
    svc #0
    ret



