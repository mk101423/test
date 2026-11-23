


// This is primarily responsible for handling the player's experience points (XP) system. It will manage the player's current XP gained, total XP, level, and the XP needed to level up. This system will also account for any bonuses or multipliers that affect XP gain. We want to also run a calculation called XP LEVEL NEEDED TO REACH. Doing some research, I purpose to use power curve system where we take base_xp which is 100 to reach from level 1 to 2, and then for subsequent levels, we multiply the base_xp by the level raised to a certain exponent (e.g., 1.5) to determine the XP needed for the next level. Another responsibility of this file is definetly handling dungeon master wins to gain xp and dungeon bosses too. The formula I wanna ue is a linear model where take Monster Gain XP = 50 * m. m = level * 0.50
section .data:
    base_xp: word 100
    exponent: word 1.5
    base_monster_xp_gain: word 50



.global xp_level_needed
.extern grab_player_data`


.section .text
xp_level_needed:
    // Let x20 be the base_xp, x21 hold the exponent base xp x19 be the current level (where we use exponent of 1.5^2 for example to say that it will take 225 xp to get from level 2 to level 3. Also we should also make a xp gain per each dungeon monster beated.base_xp. The formula for XP needed to reach the next level will be: base_xp * (exponent ^ current_level). 
    // Calculate XP needed for the next level. Load the register in to x20 the base_xp and x21 the exponent, then perform the calculation: base_xp * (current_level ^ exponent)
    // This can be used to create a progress bar needed to visualize the player's XP progress towards the next level.
    ldr x9, =base_xp
    ldr w20, [x9]
    ldr x9, =exponent
    ldr w21, [x9]
    // Call the function get_user_data
    bl grab_player_data
    // Grab x22 bit for the player's current level, which was loaded by grab_player_data into w22. This will be used in the XP calculation for the next level.
    mov w19, x22
    // Now w19 holds the player's current level, which can be used in the XP calculation for the next level. Let's do the exponent handling
    lsl w23, w19, w21
    mul w20, w20, w23
    ret

check_sp_gained:
    // This will check if the user has reached the xp needed to reach the next level and give them the sp to spend for the skill tree.
    // Let x24 hold the current XP of the player and x25 hold the XP needed for the next level. We have it in our database where it's called player_xp which holds the total xp of the user, and x25 is player_needed xp where it has the threshold to be in the level. Perhaps we can create a helper function to fetch these values from the database. We'll also create a xp_progress_bar from the database that checks user progress in their xp. We'll always check everytime user gains xp. We just check if the current XP has reached or exceeded the XP needed for the next level. Let x25 be 100. But first we will multiply the x24 by 100
    ldr x9, =player_xp
    ldr x24, [x9]
    mov x25, #100
    mul x24, x24, x25


    
    ldr x9, =player_needed_xp
    ldr x25, [x9]
    cmp x24, x25
    b.lt end_check_sp
    // If the current XP has reached or exceeded the XP needed, give SP to the player
    ldr x9, =player_sp
    ldr x20, [x9]
    add x20, x20, #1
    str x20, [x9]
end_check_sp:
    ret