//
// Dungeon Master - Battle UI
// Owner: Mahir Kamal (Dungeon and battle terminal UI, action prompts, result messages)
//
// This file only DISPLAYS the battle and READS the player's choice.
// It does not do any combat math. Combat (Kidduz) works out the damage,
// then calls the procedures here to show the screen and the results.
//
// Same style as Terminal-Design/Store/shop_beta_terminal_design.asm:
// ASCII box art in .rodata, printed with the Linux write syscall (64).
// Input uses the read syscall (63).
//
// Procedures you can call from other files:
//
//   battle_render            x0 = enemy name (address of a 0-terminated string)
//                            w1 = enemy HP, w2 = enemy max HP
//                            w3 = player HP, w4 = player max HP
//                            Draws the whole battle screen.
//
//   battle_prompt_action     Asks the player what to do and keeps asking
//                            until the input is valid. An invalid choice
//                            does not use up a turn.
//                            Returns w0: 1 = Attack, 2 = Defend, 0 = input ended (EOF)
//
//   battle_msg_encounter     x0 = enemy name              ">> The GOBLIN blocks your path!"
//   battle_msg_attack        x0 = enemy name, w1 = damage ">> You strike the GOBLIN for 12 damage!"
//   battle_msg_enemy_attack  x0 = enemy name, w1 = damage ">> The GOBLIN hits you for 5 damage!"
//   battle_msg_defend        (no arguments)               ">> You raise your guard. ..."
//   battle_msg_victory       x0 = enemy name              ">> VICTORY! You defeated the GOBLIN!"
//   battle_msg_reward        w0 = gold, w1 = xp           ">> You earned 20 GOLD and 50 XP!"
//   battle_msg_defeat        (no arguments)               ">> DEFEAT... ..."
//
// Every procedure follows the normal calling rules: arguments in x0-x4,
// result in w0, and x19-x28 are saved and restored if they are used.
//

    .equ ROW_WIDTH, 61          // characters between the left and right border
    .equ LINE_MAX, 120          // size limit for the line we are building
    .equ BAR_SLOTS, 20          // how many characters wide the HP bar is
    .equ IN_BUF_SIZE, 64

    .equ SYS_READ, 63
    .equ SYS_WRITE, 64
    .equ STDIN, 0
    .equ STDOUT, 1

.section .rodata

// Top part of the battle screen (never changes)
battle_top:
.ascii "┌─────────────────────────────────────────────────────────────┐\n"
.ascii "│    ┌──────────────────────────────────────────────────┐     │\n"
.ascii "│    │   DUNGEON MASTER  -  BATTLE!                     │     │\n"
.ascii "│    └──────────────────────────────────────────────────┘     │\n"
.ascii "│                                                             │\n"
battle_top_end:

// Empty row used between the enemy and the player
battle_blank:
.ascii "│                                                             │\n"
battle_blank_end:

// Bottom part with the action buttons (never changes)
battle_bottom:
.ascii "│                                                             │\n"
.ascii "│   ┌───────────┐   ┌───────────┐                             │\n"
.ascii "│   │ 1) ATTACK │   │ 2) DEFEND │                             │\n"
.ascii "│   └───────────┘   └───────────┘                             │\n"
.ascii "└─────────────────────────────────────────────────────────────┘\n"
battle_bottom_end:

border_left:
.ascii "│"
border_left_end:

border_right:
.ascii "│\n"
border_right_end:

newline:
.ascii "\n"

prompt_text:
.ascii "> Choose an action (1 = Attack, 2 = Defend): "
prompt_text_end:

invalid_text:
.ascii ">> Invalid choice. Type 1 or 2 and press Enter.\n"
invalid_text_end:

// Pieces used to build the dynamic rows and messages (0-terminated)
str_enemy:      .asciz "   ENEMY:  "
str_you:        .asciz "   YOU"
str_hp:         .asciz "   HP  "
str_two_spaces: .asciz "  "
str_the:        .asciz ">> The "
str_blocks:     .asciz " blocks your path!"
str_strike:     .asciz ">> You strike the "
str_for:        .asciz " for "
str_damage:     .asciz " damage!"
str_hits_you:   .asciz " hits you for "
str_defend:     .asciz ">> You raise your guard. The next hit will be weaker."
str_victory:    .asciz ">> VICTORY! You defeated the "
str_exclaim:    .asciz "!"
str_earned:     .asciz ">> You earned "
str_gold_and:   .asciz " GOLD and "
str_xp:         .asciz " XP!"
str_defeat:     .asciz ">> DEFEAT... You have fallen. Your run is over."

.section .bss
.align 2
// The line we are currently building before printing it
line_len:   .skip 4
line_buf:   .skip 128

// Keyboard input is read in chunks; these remember what is left over
in_pos:     .skip 4
in_len:     .skip 4
in_buf:     .skip IN_BUF_SIZE

.section .text

.global battle_render
.global battle_prompt_action
.global battle_msg_encounter
.global battle_msg_attack
.global battle_msg_enemy_attack
.global battle_msg_defend
.global battle_msg_victory
.global battle_msg_reward
.global battle_msg_defeat

//
// battle_render
// Draws the full battle screen with both HP bars.
//
battle_render:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    str x23, [sp, #48]

    // Keep the arguments safe, because the helpers below change x0-x4
    mov x19, x0             // enemy name
    mov w20, w1             // enemy HP
    mov w21, w2             // enemy max HP
    mov w22, w3             // player HP
    mov w23, w4             // player max HP

    // Leave a gap above the screen
    adrp x0, newline
    add x0, x0, :lo12:newline
    mov x1, #1
    bl ui_write

    // Title box
    adrp x0, battle_top
    add x0, x0, :lo12:battle_top
    mov x1, #(battle_top_end - battle_top)
    bl ui_write

    // Row: "ENEMY:  <name>"
    bl buf_reset
    adrp x0, str_enemy
    add x0, x0, :lo12:str_enemy
    bl buf_append_str
    mov x0, x19
    bl buf_append_str
    bl row_flush

    // Row: enemy HP bar
    mov w0, w20
    mov w1, w21
    bl hp_row

    // Empty row
    adrp x0, battle_blank
    add x0, x0, :lo12:battle_blank
    mov x1, #(battle_blank_end - battle_blank)
    bl ui_write

    // Row: "YOU"
    bl buf_reset
    adrp x0, str_you
    add x0, x0, :lo12:str_you
    bl buf_append_str
    bl row_flush

    // Row: player HP bar
    mov w0, w22
    mov w1, w23
    bl hp_row

    // Action buttons and bottom border
    adrp x0, battle_bottom
    add x0, x0, :lo12:battle_bottom
    mov x1, #(battle_bottom_end - battle_bottom)
    bl ui_write

    ldr x23, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

//
// hp_row (only used in this file)
// w0 = current HP, w1 = max HP
// Prints a row like:  "   HP  [##########----------]  50/100"
//
hp_row:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]

    mov w19, w0
    mov w20, w1

    bl buf_reset
    adrp x0, str_hp
    add x0, x0, :lo12:str_hp
    bl buf_append_str

    mov w0, w19
    mov w1, w20
    bl buf_append_bar

    adrp x0, str_two_spaces
    add x0, x0, :lo12:str_two_spaces
    bl buf_append_str

    mov w0, w19
    bl buf_append_num
    mov w0, #'/'
    bl buf_append_char
    mov w0, w20
    bl buf_append_num

    bl row_flush

    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

//
// battle_prompt_action
// Prints the prompt, reads one line, and checks it.
// Returns w0 = 1 (Attack), 2 (Defend), or 0 if the input ended.
//
battle_prompt_action:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]

prompt_again:
    adrp x0, prompt_text
    add x0, x0, :lo12:prompt_text
    mov x1, #(prompt_text_end - prompt_text)
    bl ui_write

    // x19 counts the characters typed, w20 remembers the first one
    mov x19, #0
    mov w20, #0

read_next_char:
    bl ui_getc
    cmp w0, #-1
    b.eq prompt_input_ended
    cmp w0, #'\n'
    b.eq check_choice
    cmp w0, #'\r'               // ignore Windows-style line endings
    b.eq read_next_char
    cbnz x19, count_char
    mov w20, w0                 // this is the first character
count_char:
    add x19, x19, #1
    b read_next_char

prompt_input_ended:
    // No more input. If nothing was typed on this line, stop the battle.
    cbnz x19, check_choice
    adrp x0, newline
    add x0, x0, :lo12:newline
    mov x1, #1
    bl ui_write
    mov w0, #0
    b prompt_done

check_choice:
    // The line must be exactly one character: '1' or '2'
    cmp x19, #1
    b.ne choice_invalid
    cmp w20, #'1'
    b.eq choice_attack
    cmp w20, #'2'
    b.eq choice_defend

choice_invalid:
    adrp x0, invalid_text
    add x0, x0, :lo12:invalid_text
    mov x1, #(invalid_text_end - invalid_text)
    bl ui_write
    b prompt_again

choice_attack:
    mov w0, #1
    b prompt_done

choice_defend:
    mov w0, #2

prompt_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

//
// Result messages
//

// x0 = enemy name -> ">> The GOBLIN blocks your path!"
battle_msg_encounter:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0

    bl buf_reset
    adrp x0, str_the
    add x0, x0, :lo12:str_the
    bl buf_append_str
    mov x0, x19
    bl buf_append_str
    adrp x0, str_blocks
    add x0, x0, :lo12:str_blocks
    bl buf_append_str
    bl msg_flush

    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// x0 = enemy name, w1 = damage -> ">> You strike the GOBLIN for 12 damage!"
battle_msg_attack:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0
    mov w20, w1

    bl buf_reset
    adrp x0, str_strike
    add x0, x0, :lo12:str_strike
    bl buf_append_str
    mov x0, x19
    bl buf_append_str
    adrp x0, str_for
    add x0, x0, :lo12:str_for
    bl buf_append_str
    mov w0, w20
    bl buf_append_num
    adrp x0, str_damage
    add x0, x0, :lo12:str_damage
    bl buf_append_str
    bl msg_flush

    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// x0 = enemy name, w1 = damage -> ">> The GOBLIN hits you for 5 damage!"
battle_msg_enemy_attack:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0
    mov w20, w1

    bl buf_reset
    adrp x0, str_the
    add x0, x0, :lo12:str_the
    bl buf_append_str
    mov x0, x19
    bl buf_append_str
    adrp x0, str_hits_you
    add x0, x0, :lo12:str_hits_you
    bl buf_append_str
    mov w0, w20
    bl buf_append_num
    adrp x0, str_damage
    add x0, x0, :lo12:str_damage
    bl buf_append_str
    bl msg_flush

    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// ">> You raise your guard. The next hit will be weaker."
battle_msg_defend:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    bl buf_reset
    adrp x0, str_defend
    add x0, x0, :lo12:str_defend
    bl buf_append_str
    bl msg_flush

    ldp x29, x30, [sp], #16
    ret

// x0 = enemy name -> ">> VICTORY! You defeated the GOBLIN!"
battle_msg_victory:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0

    bl buf_reset
    adrp x0, str_victory
    add x0, x0, :lo12:str_victory
    bl buf_append_str
    mov x0, x19
    bl buf_append_str
    adrp x0, str_exclaim
    add x0, x0, :lo12:str_exclaim
    bl buf_append_str
    bl msg_flush

    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// w0 = gold, w1 = xp -> ">> You earned 20 GOLD and 50 XP!"
battle_msg_reward:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov w19, w0
    mov w20, w1

    bl buf_reset
    adrp x0, str_earned
    add x0, x0, :lo12:str_earned
    bl buf_append_str
    mov w0, w19
    bl buf_append_num
    adrp x0, str_gold_and
    add x0, x0, :lo12:str_gold_and
    bl buf_append_str
    mov w0, w20
    bl buf_append_num
    adrp x0, str_xp
    add x0, x0, :lo12:str_xp
    bl buf_append_str
    bl msg_flush

    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// ">> DEFEAT... You have fallen. Your run is over."
battle_msg_defeat:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    bl buf_reset
    adrp x0, str_defeat
    add x0, x0, :lo12:str_defeat
    bl buf_append_str
    bl msg_flush

    ldp x29, x30, [sp], #16
    ret

//
// Helpers (only used inside this file)
//

// ui_write: x0 = address, x1 = number of bytes. Prints to the terminal.
ui_write:
    mov x2, x1
    mov x1, x0
    mov x0, #STDOUT
    mov x8, #SYS_WRITE
    svc #0
    ret

// ui_getc: returns the next typed character in w0, or -1 when input ends.
// Reads a chunk at a time so piped input with several lines also works.
ui_getc:
    adrp x9, in_pos
    add x9, x9, :lo12:in_pos
    adrp x10, in_len
    add x10, x10, :lo12:in_len
    ldr w11, [x9]
    ldr w12, [x10]
    cmp w11, w12
    b.lo getc_have_char

    // Buffer is empty: read more from the keyboard
    mov x0, #STDIN
    adrp x1, in_buf
    add x1, x1, :lo12:in_buf
    mov x2, #IN_BUF_SIZE
    mov x8, #SYS_READ
    svc #0
    cmp x0, #0
    b.le getc_end_of_input
    str w0, [x10]
    mov w11, #0

getc_have_char:
    adrp x13, in_buf
    add x13, x13, :lo12:in_buf
    ldrb w0, [x13, w11, uxtw]
    add w11, w11, #1
    str w11, [x9]
    ret

getc_end_of_input:
    str wzr, [x9]
    str wzr, [x10]
    mov w0, #-1
    ret

// buf_reset: start building a new line
buf_reset:
    adrp x0, line_len
    add x0, x0, :lo12:line_len
    str wzr, [x0]
    ret

// buf_append_char: w0 = character to add to the line
buf_append_char:
    adrp x1, line_len
    add x1, x1, :lo12:line_len
    ldr w2, [x1]
    cmp w2, #LINE_MAX
    b.hs append_char_full       // line is full, ignore the extra character
    adrp x3, line_buf
    add x3, x3, :lo12:line_buf
    strb w0, [x3, x2]
    add w2, w2, #1
    str w2, [x1]
append_char_full:
    ret

// buf_append_str: x0 = address of a 0-terminated string to add
buf_append_str:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0
append_str_loop:
    ldrb w0, [x19], #1
    cbz w0, append_str_done
    bl buf_append_char
    b append_str_loop
append_str_done:
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// buf_append_num: w0 = number to add, written in decimal
buf_append_num:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]

    // Work out the digits from right to left into a small space on the stack
    mov w9, w0
    add x20, sp, #32
    mov x19, #0
    mov w10, #10
num_digit_loop:
    udiv w11, w9, w10           // w11 = number / 10
    msub w12, w11, w10, w9      // w12 = number % 10
    add w12, w12, #'0'
    strb w12, [x20, x19]
    add x19, x19, #1
    mov w9, w11
    cbnz w9, num_digit_loop

    // Add the digits to the line in the correct order (left to right)
num_output_loop:
    cbz x19, num_done
    sub x19, x19, #1
    ldrb w0, [x20, x19]
    bl buf_append_char
    b num_output_loop
num_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// buf_append_bar: w0 = current HP, w1 = max HP
// Adds an HP bar like [##########----------]
buf_append_bar:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]

    mov w19, #0                 // number of filled slots
    cbz w1, bar_draw            // max HP of 0: show an empty bar
    cmp w0, w1
    csel w0, w0, w1, ls         // never show more than max HP
    mov w9, #BAR_SLOTS
    umull x9, w0, w9            // HP * 20 (64-bit so it can't overflow)
    mov w10, w1
    udiv x9, x9, x10            // ... / max HP
    mov w19, w9
bar_draw:
    mov w20, #BAR_SLOTS
    sub w20, w20, w19           // number of empty slots

    mov w0, #'['
    bl buf_append_char
bar_filled_loop:
    cbz w19, bar_empty_loop
    mov w0, #'#'
    bl buf_append_char
    sub w19, w19, #1
    b bar_filled_loop
bar_empty_loop:
    cbz w20, bar_close
    mov w0, #'-'
    bl buf_append_char
    sub w20, w20, #1
    b bar_empty_loop
bar_close:
    mov w0, #']'
    bl buf_append_char

    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// row_flush: prints the line inside the box borders, padded to the box width
row_flush:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

row_pad_loop:
    adrp x9, line_len
    add x9, x9, :lo12:line_len
    ldr w10, [x9]
    cmp w10, #ROW_WIDTH
    b.hs row_pad_done
    mov w0, #' '
    bl buf_append_char
    b row_pad_loop
row_pad_done:
    // If the text was too long, cut it off at the box width
    mov w10, #ROW_WIDTH
    str w10, [x9]

    adrp x0, border_left
    add x0, x0, :lo12:border_left
    mov x1, #(border_left_end - border_left)
    bl ui_write

    adrp x0, line_buf
    add x0, x0, :lo12:line_buf
    mov x1, #ROW_WIDTH
    bl ui_write

    adrp x0, border_right
    add x0, x0, :lo12:border_right
    mov x1, #(border_right_end - border_right)
    bl ui_write

    ldp x29, x30, [sp], #16
    ret

// msg_flush: prints the line followed by a newline
msg_flush:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x0, line_buf
    add x0, x0, :lo12:line_buf
    adrp x1, line_len
    add x1, x1, :lo12:line_len
    ldr w1, [x1]
    bl ui_write

    adrp x0, newline
    add x0, x0, :lo12:newline
    mov x1, #1
    bl ui_write

    ldp x29, x30, [sp], #16
    ret
