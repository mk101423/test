//
// Dungeon Master - Battle UI demo
//
// A small test program so the Battle UI can be tried on its own.
// The combat math here is a PLACEHOLDER that follows the rules in readme.md
// (damage = max(1, attack - defence), Defend weakens the next enemy hit).
// The real numbers will come from Kidduz's combat module; when that is ready,
// it calls the same battle_* procedures used below.
//
// Build and run (inside the team's Docker container):
//   aarch64-linux-gnu-as -o /tmp/battle_ui.o   Terminal-Design/Battle/battle_ui.asm
//   aarch64-linux-gnu-as -o /tmp/battle_demo.o Terminal-Design/Battle/battle_demo.asm
//   aarch64-linux-gnu-ld -o /tmp/battle_demo /tmp/battle_ui.o /tmp/battle_demo.o
//   qemu-aarch64 /tmp/battle_demo
//

    // Placeholder stats (easy to change)
    .equ PLAYER_MAX_HP, 100
    .equ PLAYER_ATTACK, 14
    .equ PLAYER_DEFENCE, 4
    .equ ENEMY_MAX_HP, 60
    .equ ENEMY_ATTACK, 9
    .equ ENEMY_DEFENCE, 2
    .equ REWARD_GOLD, 20
    .equ REWARD_XP, 50

.section .rodata
enemy_name:
    .asciz "GOBLIN"

.section .text
.global _start

.extern battle_render
.extern battle_prompt_action
.extern battle_msg_encounter
.extern battle_msg_attack
.extern battle_msg_enemy_attack
.extern battle_msg_defend
.extern battle_msg_victory
.extern battle_msg_reward
.extern battle_msg_defeat

_start:
    // w19 = enemy HP, w20 = player HP, w21 = 1 if the player is defending
    mov w19, #ENEMY_MAX_HP
    mov w20, #PLAYER_MAX_HP
    mov w21, #0

    adrp x0, enemy_name
    add x0, x0, :lo12:enemy_name
    bl battle_msg_encounter

battle_loop:
    // 1. Show the screen and ask for an action
    bl draw_screen
    bl battle_prompt_action
    cbz w0, demo_exit           // input ended: leave cleanly
    cmp w0, #2
    b.eq player_defends

    // 2. Player attacks
    mov w0, #(PLAYER_ATTACK - ENEMY_DEFENCE)
    bl at_least_one
    mov w22, w0                 // damage dealt
    cmp w19, w22
    csel w19, wzr, w19, ls      // HP never goes below 0 ...
    sub w9, w19, w22
    csel w19, w9, w19, hi       // ... otherwise subtract the damage
    adrp x0, enemy_name
    add x0, x0, :lo12:enemy_name
    mov w1, w22
    bl battle_msg_attack

    // 3. A defeated enemy does not attack back
    cbz w19, player_wins
    b enemy_turn

player_defends:
    mov w21, #1
    bl battle_msg_defend

enemy_turn:
    // 4. Enemy attacks; Defend halves the hit
    mov w0, #(ENEMY_ATTACK - PLAYER_DEFENCE)
    cbz w21, enemy_hit
    lsr w0, w0, #1
    mov w21, #0                 // Defend only lasts for one hit
enemy_hit:
    bl at_least_one
    mov w22, w0
    cmp w20, w22
    csel w20, wzr, w20, ls
    sub w9, w20, w22
    csel w20, w9, w20, hi
    adrp x0, enemy_name
    add x0, x0, :lo12:enemy_name
    mov w1, w22
    bl battle_msg_enemy_attack

    cbz w20, player_loses
    b battle_loop

player_wins:
    bl draw_screen
    adrp x0, enemy_name
    add x0, x0, :lo12:enemy_name
    bl battle_msg_victory
    mov w0, #REWARD_GOLD
    mov w1, #REWARD_XP
    bl battle_msg_reward
    b demo_exit

player_loses:
    bl draw_screen
    bl battle_msg_defeat

demo_exit:
    mov x0, #0
    mov x8, #93                 // exit
    svc #0

// draw_screen: calls battle_render with the current HP values
draw_screen:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    adrp x0, enemy_name
    add x0, x0, :lo12:enemy_name
    mov w1, w19
    mov w2, #ENEMY_MAX_HP
    mov w3, w20
    mov w4, #PLAYER_MAX_HP
    bl battle_render
    ldp x29, x30, [sp], #16
    ret

// at_least_one: w0 = damage; returns max(1, w0) (treats negative as 0)
at_least_one:
    cmp w0, #1
    b.ge at_least_one_done
    mov w0, #1
at_least_one_done:
    ret
