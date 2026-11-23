
//
// Dungeon Master - Movement
// This file handles moving the player between dungeon rooms.
// The player needs to clear an enemy room before moving forward.
//

.section .text

.global dungeon_move

.extern dungeon_get_current_room
.extern dungeon_next_room
.extern dungeon_room_type
.extern dungeon_is_room_cleared
.extern dungeon_set_current_room

//
// dungeon_move
// Takes a direction in w0.
// 1 means move forward.
//
// Returns:
//  0 = Player moved successfully
//  1 = Invalid direction or no room available
//  2 = The current room still has an enemy
//

dungeon_move:
    // Save the return address because we call other functions
    stp x29, x30, [sp, #-32]!
    mov x29, sp

    // Keep the direction safe while we check the room
    str w0, [sp, #16]

    // For now, the dungeon only allows forward movement
    cmp w0, #1
    b.ne move_invalid

    // Find out which room the player is currently in
    bl dungeon_get_current_room

    // Save the current room number
    str w0, [sp, #20]

    // Check whether this room contains an enemy or boss
    bl dungeon_room_type

    // Safe rooms don't need to be cleared
    cmp w0, #0
    b.eq check_next_room

    // Check if the player has already defeated this room's enemy
    ldr w0, [sp, #20]
    bl dungeon_is_room_cleared

    // If the room isn't cleared, don't let the player leave
    cbz w0, move_blocked

check_next_room:
    // Get the room we would move into
    ldr w0, [sp, #20]
    bl dungeon_next_room

    // -1 means there is no room after this one
    cmp w0, #-1
    b.eq move_invalid

    // Update the player's current room
    bl dungeon_set_current_room

    // Return success
    mov w0, #0
    b move_finished

move_invalid:
    mov w0, #1
    b move_finished

move_blocked:
    mov w0, #2

move_finished:
    // Restore the stack before returning
    ldp x29, x30, [sp], #32
    
    