
//
// Dungeon Master - Dungeon Test
//
// This is just for testing our dungeon system.
// It walks through Floors 1-5 and the Boss Lair, checking movement,
// enemy encounters, room progress,
// and whether the dungeon resets properly.
//
// Exit code 0 means every test passed.
// Any other exit code tells us which test failed.
//

.section .text
.global _start

_start:
    // Start a fresh game
    bl dungeon_reset

    // The player should start in room 0
    bl dungeon_get_current_room
    cmp w0, #0
    b.ne test_failed_1

    // The entrance should not have an enemy
    bl dungeon_check_encounter
    cmp w0, #0
    b.ne test_failed_2

    // Fight through Floors 1 to 5. w19 counts the floors.
    mov w19, #1
floor_loop:
    // Move forward onto the next floor
    mov w0, #1
    bl dungeon_move
    cmp w0, #0
    b.ne test_failed_3

    // Every floor should have a regular enemy
    bl dungeon_check_encounter
    cmp w0, #1
    b.ne test_failed_4

    // We should not be able to leave before winning
    mov w0, #1
    bl dungeon_move
    cmp w0, #2
    b.ne test_failed_5

    // Pretend the player won the battle
    bl dungeon_clear_current
    cmp w0, #0
    b.ne test_failed_6

    // The enemy should no longer appear
    bl dungeon_check_encounter
    cmp w0, #0
    b.ne test_failed_7

    // The dungeon is not complete until the boss is beaten
    bl dungeon_is_complete
    cmp w0, #0
    b.ne test_failed_12

    add w19, w19, #1
    cmp w19, #5
    b.le floor_loop

    // After Floor 5, move forward into the Boss Lair
    mov w0, #1
    bl dungeon_move
    cmp w0, #0
    b.ne test_failed_8

    // Room 6 should contain the boss
    bl dungeon_check_encounter
    cmp w0, #2
    b.ne test_failed_9

    // Defeat the boss
    bl dungeon_clear_current

    // The dungeon should now be completed
    bl dungeon_is_complete
    cmp w0, #1
    b.ne test_failed_10

    // There is no room after the Boss Lair
    mov w0, #1
    bl dungeon_move
    cmp w0, #1
    b.ne test_failed_13

    // A new game should reset all progress
    bl dungeon_reset
    bl dungeon_is_complete
    cmp w0, #0
    b.ne test_failed_11

    // Every test passed!
    mov w0, #0
    b test_exit

test_failed_1:
    mov w0, #1
    b test_exit

test_failed_2:
    mov w0, #2
    b test_exit

test_failed_3:
    mov w0, #3
    b test_exit

test_failed_4:
    mov w0, #4
    b test_exit

test_failed_5:
    mov w0, #5
    b test_exit

test_failed_6:
    mov w0, #6
    b test_exit

test_failed_7:
    mov w0, #7
    b test_exit

test_failed_8:
    mov w0, #8
    b test_exit

test_failed_9:
    mov w0, #9
    b test_exit

test_failed_10:
    mov w0, #10
    b test_exit

test_failed_11:
    mov w0, #11
    b test_exit

test_failed_12:
    mov w0, #12
    b test_exit

test_failed_13:
    mov w0, #13

test_exit:
    // Return the test result to Linux
    mov x8, #93
    svc #0
