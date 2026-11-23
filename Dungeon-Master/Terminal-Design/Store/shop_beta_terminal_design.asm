// Resource to use to help with ascii art

// https://asciiflow.com/#/

.section .rodata

design:
.ascii "┌─────────────────────────────────────────────────────────────┐\n"
.ascii "│    ┌──────────────────────────────────────────────────┐     │\n"
.ascii "│    │   WELCOME TO DUNGEON MASTER STORE                │     │\n"
.ascii "│    └──────────────────────────────────────────────────┘     │\n"
.ascii "│                                                             │\n"
.ascii "│   ┌────────────────────────────────────────────────────┐    │\n"
.ascii "│   │                                                    │    │\n"
.ascii "│   │   KENTRO SWORD: 40 GOLD                            │    │\n"
.ascii "│   │                                                    │    │\n"
.ascii "│   │   AEGIS SHIELD: 50 GOLD                            │    │\n"
.ascii "│   │                                                    │    │\n"
.ascii "│   │   HELMET: 40 GOLD                                  │    │\n"
.ascii "│   │                                                    │    │\n"
.ascii "│   │   HEALTH POTION: 30 GOLD                           │    │\n"
.ascii "│   │                                                    │    │\n"
.ascii "│   └────────────────────────────────────────────────────┘    │\n"
.ascii "│   ┌──────┐                             ┌──────┐             │\n"
.ascii "│   │ BUY  │                             │ SELL │             │\n"
.ascii "│   └──────┘                             └──────┘             │\n"
.ascii "└─────────────────────────────────────────────────────────────┘\n"
end:

    .section .text

    .global render

    .global _start
    // This section declares the external item labels that are used in the design section for the store items. So we can use this in our shop_items where we can randomize the arrays and place the items dynamically. 



_start:
    bl render
    mov x0, #0
    mov x8, #93   // System call number for exit
    svc #0





render:
    // Initialize x0 register with file descriptor for stdout
    mov x0, #1
    // Grab the address
    ldr x1, =design
    mov x2, #(end - design)
    mov x8, #64   // System call number for write
    svc #0
    ret
