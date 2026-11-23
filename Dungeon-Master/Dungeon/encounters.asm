
//
// Dungeon Master - Encounters
// This file checks whether the player needs to fight an enemy.
// Once an enemy is defeated, we mark the room as cleared
// so the player doesn't have to fight the same enemy again.
//

.section .text

.global dungeon_check_encounter
.global dungeon_clear_current

.extern dungeon_get_current_room
.extern dungeon_room_type
.extern dungeon_is_room_cleared
.extern dungeon_mark_room_cleared

//
// dungeon_check_encounter
// Checks the room the player is currently in.
//
// Returns:
// 0 = No enemy encounter
// 1 = Regular enemy encounter
// 2 = Boss encounter
//

dungeon_check_encounter:
    // Save the return address and make room for temporary values
    stp x29, x30, [sp, #-32]!
    mov x29, sp

    // First, find out which room the player is in
    bl dungeon_get_current_room

    // Save the room number for later
    str w0, [sp, #16]

    // Check what kind of room this is
    bl dungeon_room_type

    // Store the room type
    str w0, [sp, #20]

    // Safe rooms don't have any enemies
    cmp w0, #0
    b.eq no_encounter

    // Check if we've already defeated the enemy here
    ldr w0, [sp, #16]
    bl dungeon_is_room_cleared

    // If the room is cleared, there's nothing to fight
    cbnz w0, no_encounter

    // Return the type of enemy the player needs to fight
    ldr w0, [sp, #20]
    b encounter_finished

no_encounter:
    mov w0, #0

encounter_finished:
    // Restore the stack and return to the calling function
    ldp x29, x30, [sp], #32
    ret

//
// dungeon_clear_current
// Marks the current room as cleared after winning a battle.
//
// Returns:
// 0 = Room cleared successfully
// 1 = Invalid room
//

dungeon_clear_current:
    // Save the return address before calling other functions
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    // Get the room we're currently in
    bl dungeon_get_current_room

    // Mark this room as cleared
    bl dungeon_mark_room_cleared

    // The result is already in w0
    ldp x29, x30, [sp], #16
    ret
