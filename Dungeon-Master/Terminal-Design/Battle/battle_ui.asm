//
// Dungeon Master - Battle UI
// Owner: Mahir Kamal (Dungeon and battle terminal UI, action prompts, result messages)
//
// This file only displays the battle and reads the player's choice. It does not do
// any combat math. Combat (Kidduz) works out the damage, then calls the procedures
// here to show the screen and the results.
//
// battle_render            x0 = enemy name, w1 = enemy HP, w2 = enemy max HP,
//                          w3 = player HP, w4 = player max HP
// battle_prompt_action     returns w0: 1 = Attack, 2 = Defend, 0 = input ended
// battle_msg_encounter     x0 = enemy name
// battle_msg_attack        x0 = enemy name, w1 = damage
// battle_msg_enemy_attack  x0 = enemy name, w1 = damage
// battle_msg_defend        (no arguments)
// battle_msg_victory       x0 = enemy name
// battle_msg_reward        w0 = gold, w1 = xp
// battle_msg_defeat        (no arguments)
//

    .equ ROW_WIDTH, 61          // characters between the left and right border
    .equ LINE_MAX, 120          // size of the line buffer
    .equ BAR_SLOTS, 20          // width of the HP bar

.section .rodata
battle_top:
.ascii "\n┌─────────────────────────────────────────────────────────────┐\n"
.ascii "│    ┌──────────────────────────────────────────────────┐     │\n"
.ascii "│    │   DUNGEON MASTER  -  BATTLE!                     │     │\n"
.ascii "│    └──────────────────────────────────────────────────┘     │\n"
.asciz "│                                                             │\n"
battle_bottom:
.ascii "│                                                             │\n"
.ascii "│   ┌───────────┐   ┌───────────┐                             │\n"
.ascii "│   │ 1) ATTACK │   │ 2) DEFEND │                             │\n"
.ascii "│   └───────────┘   └───────────┘                             │\n"
.asciz "└─────────────────────────────────────────────────────────────┘\n"
border_left:    .asciz "│"
border_right:   .asciz "│\n"
newline:        .asciz "\n"
prompt_text:    .asciz "> Choose an action (1 = Attack, 2 = Defend): "
invalid_text:   .asciz ">> Invalid choice. Type 1 or 2 and press Enter.\n"

// Line templates: @ = enemy name, # = a number, $ = HP bar
row_enemy:      .asciz "   ENEMY:  @"
row_you:        .asciz "   YOU"
row_hp:         .asciz "   HP  $  #/#"
row_blank:      .asciz ""
msg_encounter:  .asciz ">> The @ blocks your path!"
msg_attack:     .asciz ">> You strike the @ for # damage!"
msg_enemy_hit:  .asciz ">> The @ hits you for # damage!"
msg_defend:     .asciz ">> You raise your guard. The next hit will be weaker."
msg_victory:    .asciz ">> VICTORY! You defeated the @!"
msg_reward:     .asciz ">> You earned # GOLD and # XP!"
msg_defeat:     .asciz ">> DEFEAT... You have fallen. Your run is over."

.section .bss
.align 2
line_len:   .skip 4             // the line being built before it is printed
line_buf:   .skip 128
in_pos:     .skip 4             // leftover keyboard input
in_len:     .skip 4
in_buf:     .skip 64

.section .text
.global battle_render, battle_prompt_action, battle_msg_encounter, battle_msg_attack
.global battle_msg_enemy_attack, battle_msg_defend, battle_msg_victory
.global battle_msg_reward, battle_msg_defeat

battle_render:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    str x23, [sp, #48]
    mov x19, x0                 // keep the arguments safe from the calls below
    mov w20, w1
    mov w21, w2
    mov w22, w3
    mov w23, w4

    ldr x0, =battle_top
    bl ui_puts
    ldr x0, =row_enemy
    mov x1, x19
    bl row
    ldr x0, =row_hp             // enemy HP
    mov w2, w20
    mov w3, w21
    bl row
    ldr x0, =row_blank
    bl row
    ldr x0, =row_you
    bl row
    ldr x0, =row_hp             // player HP
    mov w2, w22
    mov w3, w23
    bl row
    ldr x0, =battle_bottom
    bl ui_puts

    ldr x23, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

// Keeps asking until the player types exactly "1" or "2" (an invalid choice uses no turn)
battle_prompt_action:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
ask:
    ldr x0, =prompt_text
    bl ui_puts
    mov x19, #0                 // characters typed on this line
    mov w20, #0                 // first character typed
read_char:
    bl ui_getc
    cmp w0, #-1
    b.eq input_ended
    cmp w0, #'\n'
    b.eq check_choice
    cmp w0, #'\r'               // ignore Windows line endings
    b.eq read_char
    cmp x19, #0
    csel w20, w0, w20, eq
    add x19, x19, #1
    b read_char
input_ended:
    cbnz x19, check_choice
    ldr x0, =newline
    bl ui_puts
    mov w0, #0
    b ask_done
check_choice:
    cmp x19, #1
    b.ne invalid
    sub w0, w20, #'0'           // '1' -> 1, '2' -> 2
    cmp w0, #1
    b.eq ask_done
    cmp w0, #2
    b.eq ask_done
invalid:
    ldr x0, =invalid_text
    bl ui_puts
    b ask
ask_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// Result messages: put the template in x0, the name in x1, numbers in w2/w3
battle_msg_encounter:
    mov x1, x0
    ldr x0, =msg_encounter
    b say
battle_msg_attack:
    mov w2, w1
    mov x1, x0
    ldr x0, =msg_attack
    b say
battle_msg_enemy_attack:
    mov w2, w1
    mov x1, x0
    ldr x0, =msg_enemy_hit
    b say
battle_msg_defend:
    ldr x0, =msg_defend
    b say
battle_msg_victory:
    mov x1, x0
    ldr x0, =msg_victory
    b say
battle_msg_reward:
    mov w3, w1
    mov w2, w0
    ldr x0, =msg_reward
    b say
battle_msg_defeat:
    ldr x0, =msg_defeat
    b say

//
// Helpers (only used in this file)
//

// say: fills in a template (see build_line) and prints it as one line
say:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    bl build_line
    mov w0, #'\n'
    bl buf_add_char
    ldr x0, =line_buf
    ldr x1, =line_len
    ldr w1, [x1]
    bl ui_write
    ldp x29, x30, [sp], #16
    ret

// row: fills in a template and prints it inside the box borders, padded to the box width
row:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    bl build_line
pad:
    ldr x9, =line_len
    ldr w10, [x9]
    cmp w10, #ROW_WIDTH
    b.hs padded
    mov w0, #' '
    bl buf_add_char
    b pad
padded:
    ldr x0, =border_left
    bl ui_puts
    ldr x0, =line_buf
    mov x1, #ROW_WIDTH          // text that is too long gets cut off at the border
    bl ui_write
    ldr x0, =border_right
    bl ui_puts
    ldp x29, x30, [sp], #16
    ret

// build_line: x0 = template, x1 = name, w2 = first number, w3 = second number
// Copies the template into line_buf. @ becomes the name, # becomes the next number,
// $ becomes an HP bar showing the first number out of the second.
build_line:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    mov x19, x0
    mov x20, x1
    mov w21, w2
    mov w22, w3
    ldr x9, =line_len
    str wzr, [x9]               // start with an empty line
next:
    ldrb w0, [x19], #1
    cbz w0, built
    cmp w0, #'@'
    b.eq put_name
    cmp w0, #'#'
    b.eq put_number
    cmp w0, #'$'
    b.eq put_bar
    bl buf_add_char             // normal character: copy it
    b next
put_name:
    mov x0, x20
    bl buf_add_str
    b next
put_number:
    mov w0, w21
    bl buf_add_num
    mov w21, w22                // the next # uses the second number
    b next
put_bar:
    mov w0, w21
    mov w1, w22
    bl buf_add_bar
    b next
built:
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// buf_add_char: w0 = character to add to the line (ignored if the line is full)
buf_add_char:
    ldr x1, =line_len
    ldr w2, [x1]
    cmp w2, #LINE_MAX
    b.hs full
    ldr x3, =line_buf
    strb w0, [x3, x2]
    add w2, w2, #1
    str w2, [x1]
full:
    ret

// buf_add_str: x0 = 0-terminated string to add
buf_add_str:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov x19, x0
str_loop:
    ldrb w0, [x19], #1
    cbz w0, str_done
    bl buf_add_char
    b str_loop
str_done:
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// buf_add_num: w0 = number to add in decimal
buf_add_num:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    add x20, sp, #32            // digits are stored here, last digit first
    mov x19, #0
    mov w10, #10
digit:
    udiv w11, w0, w10           // w11 = number / 10
    msub w12, w11, w10, w0      // w12 = number % 10
    add w12, w12, #'0'
    strb w12, [x20, x19]
    add x19, x19, #1
    mov w0, w11
    cbnz w0, digit
print_digit:                    // add them back in the right order
    sub x19, x19, #1
    ldrb w0, [x20, x19]
    bl buf_add_char
    cbnz x19, print_digit
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #48
    ret

// buf_add_bar: w0 = HP, w1 = max HP. Adds a bar like [##########----------]
buf_add_bar:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov w19, #0                 // filled slots = HP * 20 / max HP
    cbz w1, bar_start
    cmp w0, w1
    csel w0, w0, w1, ls         // never more than max HP
    mov w9, #BAR_SLOTS
    umull x0, w0, w9
    mov w1, w1
    udiv x0, x0, x1
    mov w19, w0
bar_start:
    mov w0, #'['
    bl buf_add_char
    mov w20, #0
bar_slot:
    cmp w20, w19
    mov w0, #'#'                // filled slot
    mov w9, #'-'                // empty slot
    csel w0, w0, w9, lo
    bl buf_add_char
    add w20, w20, #1
    cmp w20, #BAR_SLOTS
    b.lo bar_slot
    mov w0, #']'
    bl buf_add_char
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// ui_puts: x0 = 0-terminated string to print. Works out the length, then falls into ui_write.
ui_puts:
    mov x1, x0
puts_len:
    ldrb w2, [x1], #1
    cbnz w2, puts_len
    sub x1, x1, x0
    sub x1, x1, #1

// ui_write: x0 = address, x1 = number of bytes
ui_write:
    mov x2, x1
    mov x1, x0
    mov x0, #1                  // stdout
    mov x8, #64                 // write
    svc #0
    ret

// ui_getc: returns the next typed character in w0, or -1 when input has ended
ui_getc:
    ldr x9, =in_pos
    ldr x10, =in_len
    ldr w11, [x9]
    ldr w12, [x10]
    cmp w11, w12
    b.lo have_char
    mov x0, #0                  // stdin
    ldr x1, =in_buf
    mov x2, #64
    mov x8, #63                 // read
    svc #0
    cmp x0, #0
    b.le no_input
    str w0, [x10]
    mov w11, #0
have_char:
    ldr x13, =in_buf
    ldrb w0, [x13, w11, uxtw]
    add w11, w11, #1
    str w11, [x9]
    ret
no_input:
    str wzr, [x9]
    str wzr, [x10]
    mov w0, #-1
    ret
