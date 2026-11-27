
//
// Dungeon Master - Game State
//
// This file keeps track of the player's progress in the dungeon.
// We store the current room and remember which rooms have
// already been cleared.
//
// When a new game starts, we reset everything so the player
// can start exploring the dungeon again.
//

.equ LAST_ROOM, 6       // Entrance, Floors 1-5, Boss Lair

.section .data
.align 2

// The player always starts in room 0
current_room:
    .word 0

// Each value tells us whether a room has been cleared.
// 0 means the room hasn't been cleared yet.
// 1 means the player has finished that room.
//
// Room 0 is the entrance, so it starts as cleared.
room_cleared:
    .word 1, 0, 0, 0, 0, 0, 0

.section .text

.global dungeon_reset
.global dungeon_get_current_room
.global dungeon_set_current_room
.global dungeon_is_room_cleared
.global dungeon_mark_room_cleared
.global dungeon_is_complete

//
// dungeon_reset
//
// Called whenever the player starts a new game.
// It puts the player back at the entrance and
// resets the progress of all dungeon rooms.
//

dungeon_reset:
    // Get the address where the current room is stored
    adrp x1, current_room
    add x1, x1, :lo12:current_room

    // Move the player back to room 0
    mov w0, #0
    str w0, [x1]

    // Get the room progress table
    adrp x1, room_cleared
    add x1, x1, :lo12:room_cleared

    // The entrance starts cleared because there is no enemy
    mov w0, #1
    str w0, [x1]

    // Reset Floors 1-5 and the Boss Lair to "not cleared"
    mov w2, #1
reset_room_loop:
    str wzr, [x1, w2, uxtw #2]
    add w2, w2, #1
    cmp w2, #LAST_ROOM
    b.le reset_room_loop

    ret

//
// dungeon_get_current_room
//
// Returns the room number the player is currently in.
// The room number is returned in w0.
//

dungeon_get_current_room:
    adrp x1, current_room
    add x1, x1, :lo12:current_room

    ldr w0, [x1]
    ret

//
// dungeon_set_current_room
//
// Takes the new room number in w0.
// Checks whether that room exists before updating it.
//
// Returns:
// 0 = Room updated successfully
// 1 = Invalid room number
//

dungeon_set_current_room:
    // Valid rooms are 0 (Entrance) to LAST_ROOM (Boss Lair)
    cmp w0, #0
    b.lt set_room_invalid

    cmp w0, #LAST_ROOM
    b.gt set_room_invalid

    // Save the new room number
    adrp x1, current_room
    add x1, x1, :lo12:current_room

    str w0, [x1]

    mov w0, #0
    ret

set_room_invalid:
    mov w0, #1
    ret

//
// dungeon_is_room_cleared
//
// Takes a room number in w0.
// Checks whether the enemy in that room was defeated.
//
// Returns:
// 1 = Room has been cleared
// 0 = Room hasn't been cleared
// -1 = Invalid room number
//

dungeon_is_room_cleared:   
    // I wanna create a function that checks if a room has been cleared, and returns the appropriate status. And we can connect this with the database file to give the user xp gained for cleared rooms.
    // Make sure the room number is valid
    cmp w0, #0
    b.lt check_room_invalid

    cmp w0, #LAST_ROOM
    b.gt check_room_invalid

    // Find the room's progress in the table
    adrp x1, room_cleared
    add x1, x1, :lo12:room_cleared

    ldr w0, [x1, w0, uxtw #2]
    ret

check_room_invalid:
    mov w0, #-1
    ret

//
// dungeon_mark_room_cleared
//
// Takes a room number in w0.
// Marks that room as completed after the player wins.
//
// Returns:
// 0 = Room marked successfully
// 1 = Invalid room number
//

dungeon_mark_room_cleared:
    // Check the room number before changing anything
    cmp w0, #0
    b.lt mark_room_invalid

    cmp w0, #LAST_ROOM
    b.gt mark_room_invalid

    // Find where this room's progress is stored
    adrp x1, room_cleared
    add x1, x1, :lo12:room_cleared

    // Work out the position of this room in the table
    add x1, x1, w0, uxtw #2

    // Mark the room as cleared
    mov w2, #1
    str w2, [x1]

    mov w0, #0
    ret

mark_room_invalid:
    mov w0, #1
    ret

//
// dungeon_is_complete
//
// Checks whether the player has defeated the final boss.
// The Boss Lair (room 6) comes after Floor 5, so clearing it
// means the dungeon has been completed.
//
// Returns:
// 1 = Dungeon completed
// 0 = Dungeon not completed
//

dungeon_is_complete:
    // Get the room progress table
    adrp x1, room_cleared
    add x1, x1, :lo12:room_cleared

    // Check whether the Boss Lair is cleared
    ldr w0, [x1, #(LAST_ROOM * 4)]

    ret
