//Written for SAMD21 G18A - board: SAMD21 M0 Mini
.global main
.cpu cortex-m0plus
.code	16
.thumb
.global onTimer, .isr_vector, onButton, onTimer

.equ PORT, 0x41004400
.equ PM, 0x40000400
.equ NVIC, 0xE000E100
.equ GCC, 0x40000C00
.equ EIC, 0x40001800
.equ TC3, 0x42002C00

.section .data
timerEnd: .word 0x0000FFFF 
debounce: .byte 0x0


.align 4
.section .isr_vector,"a",%progbits
  .word   0x20007FFC  // addr 0x00000000 Top of Stack -
  .word   Reset_Handler
  .word   NMI_Handler // system functions are not implemented, do not call
  .word   HardFault_Handler
  .word   0
  .word   0
  .word   0
  .word   0
  .word   0
  .word   0
  .word   0
  .word   SVC_Handler
  .word   0
  .word   0
  .word   PendSV_Handler
  .word   SysTick_Handler
  .word   0 // prvi user defined interrupt
  .word   0
  .word   0
  .word   0
  .word   onButton //EIC
  .word   0
  .word   0
  .word   0
  .word   0
  .word   0
  .word   0
  .word   0
  .word   0
  .word   0
  .word   0
  .word   0
  .word   0
  .word   0
  .word   onTimer //Timer 3



.section .text
.thumb_func
main:


    ldr r0, =PM //Power manager

    ldr r1, [r0, #0x20] //APBCMASK
    mov r3, #1
    lsl r3, r3, #11
    orr r1, r1, r3
    str r1, [r0, #0x20] //enable power to Timer3
    

    ldr r0, =PORT
    mov r3, #0b111   
    lsl r3, r3, #8
    str r3, [r0] // configure pins D1, D3, D4 for output (PA10, PA9, PA8)



    add r0, #0x30 //offset for PMUX registers
    mov r3, #0
    strb r3, [r0, #10] //set interrupt function for PA20 (D6)

    ldr r0, =PORT
    add r0, #0x40 //offset for PinCfg registers
    mov r3, #0b101
    strb r3, [r0, #20] // enable functions for PA20 (D6)

    

    ldr r0, =NVIC  //nested interrupt controller
    ldr r1, =0b010000 // EIC line
    mov r3, #1
    lsl r3, r3, #18 // timer3 line
    orr r1, r1, r3
    str r1, [r0] // enable interrupts for EIC and Timer3


    ldr r0, =GCC // generic clock controller

    ldr r1, =0b1000010000011000000101 // clock generator 5, spoji na OSC8M, ukljuci
    str r1, [r0, #4]

    ldr r1, =0b0100010100000101 // EIC, spoji na generator 5, enable
    strh r1,[r0, #2]

    ldr r1, =0b0100010100011011 // Timer 3, spoji na generator 5, enable
    strh r1,[r0, #2]
    


    ldr r0, =EIC // external interrupt controller

    mov r1, #2
    strb r1, [r0] //enable EIC

    ldr r1, =0b10100 // enable interrupt 4 (PA20, D6)
    str r1, [r0, #0x0C]

    mov r1, #0b1001 
    lsl r1, #16 // 4(width of config) * 4(line) = 16
    str r1, [r0, #0x18] // configure interrupt 4, filter + trigger on HIGH
    


    ldr r0, =TC3 // Timer 3

    mov r1, #0b0001
    strb r1, [r0, #0x0D] //enable overflow interrupt for Timer3

    ldr r2, =timerEnd
    ldr r1, [r2]
    strh r1, [r0, #0x18] // set TOP to MAX; sat je 8MHZ prescale je 1024 znaci ovo bi trebalo da obezbjedi period od 8.388608 sekundi + 15 clock cycle na ulazak u ISR

    ldr r1, =0b0010111100100010 //enable timer, 16 bit, match frequency mode, prescale 1024, run in standby, reset on prescale clock
    strh r1, [r0]





looyp:    
    WFI
    b looyp


.thumb_func
onButton:

    ldr r0, =debounce
    ldrb r1, [r0]

    cmp r1, #1
    beq exit1

    mov r1, #1
    str r1, [r0] //disable button press

    ldr r0, =PORT
    ldr r1, [r0, #0x10] // OUTPUT values
    mov r2, #0b111
    lsl r2, #8
    and r1, r1, r2 //filter values for PA 8,9,10

    mov r3, #1
    lsl r3, r3, #9 //middle diode, PA9 (D3)

    cmp r1, r3
    beq won //pritisnuto dugme na srednjoj diodi

lost:

    mov r1, #0
    str r1, [r0, #0x10] // turn off all diodes (game over)

    ldr r0, =TC3
    ldr r2, =timerEnd
    ldr r1, =0xFFFF
    str r1, [r2] //store the new game speed
    strh r1, [r0, #0x18] //update timer

    b exit1

won:

    ldr r0, =TC3
    ldr r2, =timerEnd
    ldr r1, [r2]
    lsr r1, r1, #1 //speed up game 
    str r1, [r2] //store the new game speed
    strh r1, [r0, #0x18] //update timer

    ldr r1, =0b01000000
    strb r1, [r0, #0x5] //retriger Timer3

exit1:

    ldr r0, =EIC
    mov r1, #0xFF
    str r1, [r0, #0x10] //disable all EIC flags


    ldr r0, =NVIC 
    ldr r2, =0b010000 // EIC line
    ldr r1, [r0, #16]
    eor r1, r1, r2
    str r1, [r0, #16] //clear interrupt for EIC

    BX LR




.thumb_func
onTimer:

    ldr r0, =debounce
    mov r1, #0
    str r1, [r0] //enable putton press

    ldr r0, =PORT
    ldr r1, [r0, #0x10] // OUTPUT values
    mov r2, #0b111
    lsl r2, #8
    and r1, r1, r2 //filter values for PA 8,9,10
    lsl r1, #1 // turn on the next diode for the game

    and r1, r1, r2 //filter values for PA 8,9,10 again
    cmp r1, #0 // check if filter removed all values, if so start from the beginning
    beq startOver

    str r1, [r0, #0x10] // change diodes to new state
    b exitt
startOver:

    mov r1, #1
    lsl r1, #8
    str r1, [r0, #0x10] // turn on only the first output

exitt:

    ldr r0, =TC3
    mov r1, #0xF
    strb r1, [r0, #0xE] //clear all Timer3 interrupt flags

    ldr r0, =NVIC 
    mov r3, #1
    lsl r3, r3, #18 // timer3 line
    ldr r1, [r0, #16]
    eor r1, r1, r3
    str r1, [r0, #16] //clear interrupt flag for Timer3

    BX LR
