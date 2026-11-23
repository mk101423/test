
//
// Dungeon Master - Rooms
// This file keeps track of the different rooms in our dungeon.
// Each room has a name, a type, and a path to the next room.
//
// Room 0: Entrance
// Room 1: Battle Chamber
// Room 2: Boss Room
//

.section .rodata

// Names of the rooms that the player can visit
entrance_name:
    .asciz "Dungeon Entrance"

battle_name:
    .asciz "Battle Chamber"

boss_name:
    .asciz "Boss Room"

// Store the addresses of each room name in a table
.align 3
room_names:
    .quad entrance_name
    .quad battle_name
    .quad boss_name

// Room types:
// 0 = Safe room
// 1 = Enemy room
// 2 = Boss room
.align 2
room_types:
    .word 0
    .word 1
    .word 2

// Each room points to the next room.
// -1 means there is no room after this one.
room_connections:
    .word 1
    .word 2
    .word -1

.section .text

.global dungeon_room_name
.global dungeon_room_type
.global dungeon_next_room

//
// dungeon_room_name
// Takes a room number in w0.
// Returns the address of that room's name in x0.
// If the room number is invalid, returns 0.
//

dungeon_room_name:
    cmp w0, #0
    b.lt invalid_room_name

    cmp w0, #2
    b.gt invalid_room_name

    // Find the room name using its position in the table
    adrp x1, room_names
    add x1, x1, :lo12:room_names

    ldr x0, [x1, w0, uxtw #3]
    ret

invalid_room_name:
    mov x0, #0
    ret

//
// dungeon_room_type
// Takes a room number in w0.
// Returns the room type in w0.
// Returns -1 if the room doesn't exist.
//

dungeon_room_type:
    cmp w0, #0
    b.lt invalid_room_type

    cmp w0, #2
    b.gt invalid_room_type

    // Look up whether this room is safe, an enemy room, or a boss room
    adrp x1, room_types
    add x1, x1, :lo12:room_types

    ldr w0, [x1, w0, uxtw #2]
    ret

invalid_room_type:
    mov w0, #-1
    ret

//
// dungeon_next_room
// Takes the current room number in w0.
// Returns the number of the next room.
// Returns -1 if there is no next room.
//

dungeon_next_room:
    cmp w0, #0
    b.lt invalid_next_room

    cmp w0, #2
    b.gt invalid_next_room

    // Use the room number to find where the player can go next
    adrp x1, room_connections
    add x1, x1, :lo12:room_connections

    ldr w0, [x1, w0, uxtw #2]
    ret

invalid_next_room:
    mov w0, #-1
    ret
