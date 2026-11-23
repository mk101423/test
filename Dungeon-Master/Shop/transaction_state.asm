


.section .data
    // Transaction state variables
    transaction_success: .word 0
    transaction_failure: .word 0
extern grab_user_currency_data
extern xp_gained




.global transaction_success_currency
.global transaction_failure_currency



.section .text

transaction_success_currency:
    // This is a function that handles a successful transaction based on user currency and updates the transaction state accordingly. If the transaction is a failure via the user has insufficent funds, it will be handled separately. Let x19 be the result of grab_user_currency_data. then we let x20 be the shop item and see if it's sufficent currency, if not then we return the state of transaction_failure
    bl grab_user_currency_data
    mov x19, x0
    // Assume x20 contains the shop item cost
    cmp x19, x20
    blt transaction_failure_currency
    mov x0, #1
    str x0, =transaction_success
    ret
transaction_failure_currency:
    mov x0, #0
    str x0, =transaction_failure
    ret