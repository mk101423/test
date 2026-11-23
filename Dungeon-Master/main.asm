# Main program: connects the program's modules. This is a testing file for docker

.section .data
.align 3      
msg: .ascii "Hello, World!\n"
len = . - msg
.section .text
.global _start





_start: 
    # Print the message
    mov x0, #1 
    # Load the address of the message into x1
    ldr x1, =msg
    # Load the length of the message into x2
    mov x2, len  
    # Make the system call to write the message to stdout
    mov x8, #64
    # Make the system call
    svc #0
    # Exit the program
    mov x0, #0
    mov x8, #93
    svc #0



