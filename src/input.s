.globalzp vars, joy1_held, joy1_pressed
.export poll_input

joy1 = $4016
joy2 = $4016

.zeropage
    joy1_held: .res 1
    joy1_pressed: .res 1

.segment "CODE7"
.proc poll_input
    LDY joy1_held
    LDX #1
    STX joy1 ; begin strobe
    STX joy1_held
    DEX
    STX joy1 ; end strobe
    loop:
        LDA joy1
        LSR A
        ROL joy1_held
        BCC loop

    TYA
    EOR joy1_held
    AND joy1_held
    STA joy1_pressed
    RTS
.endproc
