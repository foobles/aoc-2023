.linecont +

.include "ppu_inc.s"
.include "input_inc.s"

mul_u8_u8_u16 := tepples_mul_u8_u8_u16 ; Can switch to foobles_mul_u8_u8_u16

.global nmi_handler, reset_handler, irq_handler
.global solution, set_bank, print_dbyte_to_solution, print_tbyte_to_solution, mul_u8_u8_u16
.globalzp vars, joy1_pressed, mul_out

.import poll_input
.import solve_day1_part1, solve_day1_part2
.import solve_day2_part1, solve_day2_part2

.segment "CHARS0"
.incbin "chr0.chr"

.segment "CHARS1"
.incbin "chr1.chr"

ps_buffer := $100

.zeropage
    vars: .res 128
    local_ppumask: .res 1
    local_ppuctrl: .res 1
    frame_done: .res 1
    computation_queued: .res 1
    ps_end: .res 1

    selected_problem: .res 1

    mul_in: .res 2
    mul_out: .res 2

.bss
    .align $100
    local_oam: .res $100

    SOLUTION_BUFFER_LEN = 16
    solution: .res SOLUTION_BUFFER_LEN


.segment "CODE7"
.proc reset_handler
    SEI
    CLD
    LDX #$FF
    TXS
    INX
    STX ppuctrl
    STX ppumask

    ;;; Set MMC1 control:
    ;;;     One 8kb CHR bank
    ;;;     First PRG bank switchable
    ;;;     Second PRG bank fixed to last
    ;;;     Single-screen mirroring (low nametable)
    LDA #%01100
    STA $8000
    LSR A
    STA $8000
    LSR A
    STA $8000
    LSR A
    STA $8000
    LSR A
    STA $8000
    LSR A

    BIT ppustatus
    wait_ppu_1:
        BIT ppustatus
        BPL wait_ppu_1

    LDA #0
    TAX
    clear_ram:
        STA $00,X
        STA $100,X
        STA $200,X
        STA $300,X
        STA $400,X
        STA $500,X
        STA $600,X
        STA $700,X
        DEX
        BNE clear_ram

    wait_ppu_2:
        BIT ppustatus
        BPL wait_ppu_2

    JSR setup_palettes
    JSR draw_nametable

    LDA #%10001000
    STA local_ppuctrl
    STA ppuctrl
    LDA #%00001110 ; enable tile rendering
    STA local_ppumask
    STA ppumask

    JSR print_heading

    ::main_loop:
        LSR frame_done
        JSR poll_input
        JSR handle_input

        LDA computation_queued
        BPL :+
            JSR run_computation
        :
        LDA #$FF
        STA frame_done
        JMP *
.endproc


.proc run_computation
        jump_addr := vars+0

        LSR A
        STA computation_queued
        JSR clear_solution_buffer
    load_routine:
        LDX selected_problem
        LDA solution_routine_los,X
        STA jump_addr+0
        LDA solution_routine_his,X
        STA jump_addr+1
        LDA solution_banks,X
        JSR set_bank

    push_return_addr:
        LDA #>(solution_ret-1)
        PHA
        LDA #<(solution_ret-1)
        PHA

    call_solution:
        LDA #0
        STA ppuctrl ; Disable NMIs
        JMP (jump_addr)

    solution_ret:
        LDA local_ppuctrl ; Re-enable NMIs
        STA ppuctrl
        JMP print_solution
.endproc

NUM_SOLUTIONS = 2
.define SOLUTION_ROUTINES \
    solve_day1_part1, solve_day1_part2, \
    solve_day2_part1, solve_day2_part2
solution_routine_los: .lobytes SOLUTION_ROUTINES
solution_routine_his: .hibytes SOLUTION_ROUTINES
solution_banks: .byte $00, $00, $02, $02


.proc handle_input
        LDA #JOY_BUTTON_A
        BIT joy1_pressed
        BEQ handle_b
        LDA #$FF
        STA computation_queued

    handle_b:
        LDA #JOY_BUTTON_B
        BIT joy1_pressed
        BEQ handle_left
        LDA selected_problem
        EOR #1
        STA selected_problem
        JSR print_heading

    handle_left:
        LDA #JOY_BUTTON_LEFT
        BIT joy1_pressed
        BEQ handle_right
        LDA selected_problem
        SEC
        SBC #2
        BCC handle_right
        STA selected_problem
        JSR print_heading

    handle_right:
        LDA #JOY_BUTTON_RIGHT
        BIT joy1_pressed
        BEQ return
        LDA selected_problem
        CLC
        ADC #2
        CMP #((NUM_SOLUTIONS - 1) << 1) + 2
        BCS return
        STA selected_problem
        JSR print_heading

    return:
        RTS
.endproc


.proc irq_handler
    RTI
.endproc


.proc nmi_handler
    BIT frame_done
    BMI :+
        RTI
    :
    LDA #>local_oam
    STA oamdma

    LDA local_ppumask
    STA ppumask
    LDA local_ppuctrl
    STA ppuctrl

    LDX #$FF
    TXS
    popslide:
        PLA ; get count
        BEQ return
        BMI write_repeat
        write_data:
            TAX
            PLA
            STA ppuaddr
            PLA
            STA ppuaddr
            write_data_loop:
                PLA
                STA ppudata
                DEX
                BNE write_data_loop
                BEQ popslide

        write_repeat:
            AND #$7F
            TAX
            PLA
            STA ppuaddr
            PLA
            STA ppuaddr
            PLA
            write_repeat_loop:
                STA ppudata
                DEX
                BNE write_repeat_loop
                BEQ popslide

    return:
        LDX #0
        STX ppuscroll
        STX ppuscroll
        STX ps_end
        STX ps_buffer
        DEX
        TXS
        JMP main_loop
.endproc


.proc set_bank
    STA $E000
    LSR A
    STA $E000
    LSR A
    STA $E000
    LSR A
    STA $E000
    LSR A
    STA $E000
    RTS
.endproc


.proc clear_solution_buffer
    LDA #0
    LDX #SOLUTION_BUFFER_LEN
    loop:
        STA solution-1,X
        DEX
        BNE loop
    RTS
.endproc


;;; Converts 24 bit number to decimal array in the solution buffer.
;;;
;;; Arguments:
;;;     A: Lo byte of tbyte
;;;     X: Mid byte of tbyte
;;;     Y: Hi byte of tbyte
.proc print_tbyte_to_solution
    tbyte := vars+0
        STA tbyte+0
        STX tbyte+1
        STY tbyte+2

    find_ten_millions:
        LDA tbyte+0
        SEC
        SBC #(10000000 .mod 256)
        TAX
        LDA tbyte+1
        SBC #((10000000 >> 8) .mod 256)
        TAY
        LDA tbyte+2
        SBC #(10000000 >> 16)
        BCC find_millions
        STX tbyte+0
        STY tbyte+1
        STA tbyte+2
        INC solution+7 ; ten millions digit
        BNE find_ten_millions

    find_millions:
        LDA tbyte+0
        SEC
        SBC #(1000000 .mod 256)
        TAX
        LDA tbyte+1
        SBC #((1000000 >> 8) .mod 256)
        TAY
        LDA tbyte+2
        SBC #(1000000 >> 16)
        BCC find_hundred_thousands
        STX tbyte+0
        STY tbyte+1
        STA tbyte+2
        INC solution+6 ; millions digit
        BNE find_millions

    find_hundred_thousands:
        LDA tbyte+0
        SEC
        SBC #(100000 .mod 256)
        TAX
        LDA tbyte+1
        SBC #((100000 >> 8) .mod 256)
        TAY
        LDA tbyte+2
        SBC #(100000 >> 16)
        BCC find_ten_thousands
        STX tbyte+0
        STY tbyte+1
        STA tbyte+2
        INC solution+5 ; hundred thousands digit
        BNE find_hundred_thousands

    find_ten_thousands:
        LDA tbyte+0
        SEC
        SBC #(10000 .mod 256)
        TAX
        LDA tbyte+1
        SBC #((10000 >> 8) .mod 256)
        TAY
        LDA tbyte+2
        SBC #(10000 >> 16)
        BCC ::find_thousands
        STX tbyte+0
        STY tbyte+1
        STA tbyte+2
        INC solution+4 ; ten thousands digit
        BNE find_ten_thousands
.endproc

;;; Converts 16 bit number to decimal array in the solution buffer.
;;;
;;; Arguments:
;;;     A: Lo byte of dbyte
;;;     X: Hi byte of dbyte
.proc print_dbyte_to_solution
    dbyte := vars+0

        STA dbyte+0
        STX dbyte+1

    find_ten_thousands:
        LDA dbyte+0
        SEC
        SBC #(10000 .mod 256)
        TAX
        LDA dbyte+1
        SBC #(10000 / 256)
        BCC find_thousands
        STX dbyte+0
        STA dbyte+1
        INC solution+4 ; ten thousands digit
        BNE find_ten_thousands

    find_thousands:
        LDA dbyte+0
        SEC
        SBC #(1000 .mod 256)
        TAX
        LDA dbyte+1
        SBC #(1000 / 256)
        BCC find_hundreds
        STX dbyte+0
        STA dbyte+1
        INC solution+3 ; thousands digit
        BNE find_thousands

    find_hundreds:
        LDA dbyte+0
        SEC
        SBC #100
        TAX
        LDA dbyte+1
        SBC #0
        BCC find_tens
        STX dbyte+0
        STA dbyte+1
        INC solution+2 ; hundreds digit
        BNE find_hundreds

    find_tens:
        LDA dbyte+0
        SEC
        SBC #10
        BCC find_ones
        STA dbyte+0
        INC solution+1 ; tens digit
        BNE find_tens

    find_ones:
        LDA dbyte+0
        STA solution+0 ; ones_digit

        RTS
.endproc

find_thousands = print_dbyte_to_solution::find_thousands

;;; Unsigned 8x8->16 bit multiplication
;;; Implementation without reference by Foobles.
;;;
;;; Arguments:
;;;     A: First operand
;;;     X: Second operand
;;;
;;; Output:
;;;     mul_out: 16 bit product
.proc foobles_mul_u8_u8_u16
        STX mul_in+0
        CMP mul_in+0
        BCC clear_vars
    swap_inputs:
        TAX
        LDA mul_in+0
        STX mul_in+0

    clear_vars:
        LDX #0
        STX mul_in+1
        STX mul_out+0
        STX mul_out+1
    loop:
        LSR A
        BCC shift_up
    add_out:
        TAX
        LDA mul_in+0
        CLC
        ADC mul_out+0
        STA mul_out+0
        LDA mul_in+1
        ADC mul_out+1
        STA mul_out+1
        TXA
    shift_up:
        BEQ done
        ASL mul_in+0
        ROL mul_in+1
        BCC loop ; BRA

    done:
        RTS
.endproc


;;; Unsigned 8x8->16 bit multiplication
;;; Implementation originally by Tepples, modified by Foobles.
;;;
;;; Arguments:
;;;     A: First operand
;;;     X: Second operand
;;;
;;; Output:
;;;     mul_out: 16 bit product
.proc tepples_mul_u8_u8_u16
        LSR A
        STA mul_out+0
        DEX
        STX mul_in
        LDA #0
    .repeat 8
        BCC :+
            ADC mul_in
        :
        ROR A
        ROR mul_out+0
    .endrepeat
        STA mul_out+1
        RTS
.endproc


.proc setup_palettes
    LDA #$3F
    STA ppuaddr
    LDA #$00
    STA ppuaddr

    LDX #$FF
    write_colors:
        INX
        LDA palette_bytes,X
        STA ppudata
        BNE write_colors

    ;;; Keep away vampires (CRAM corruption)
    LDA #$3F
    STA ppuaddr
    LDA #$00
    STA ppuaddr
    STA ppuaddr
    STA ppuaddr
    RTS

    palette_bytes:
        ;;; BG color + Tile palette 0
        .byte $20, $0F, $1B, $2A ; white, black, dark green, light green
        .byte $FF, $0F, $16, $26 ; black, dark red/pink, light red/pink
        .byte $00 ; sentinel
.endproc


.proc print_solution
    digit_count := vars+0

    LDX ps_end

    LDY #17
    find_high_digit:
        DEY
        LDA solution-1,Y
        BNE high_digit_found
        CPY #1
        BNE find_high_digit

    high_digit_found:
    STY digit_count
    LDA #16
    STA ps_buffer+0,X
    LDA #$22
    STA ps_buffer+1,X
    LDA #$04
    STA ps_buffer+2,X


    print_digits:
        LDA solution-1,Y
        STA ps_buffer+3,X
        INX
        DEY
        BNE print_digits

    LDA #16
    SEC
    SBC digit_count
    TAY
    LDA #$FF
    print_spaces:
        STA ps_buffer+3,X
        INX
        DEY
        BNE print_spaces

    LDA #0
    STA ps_buffer+3,X
    TXA
    CLC
    ADC #3
    STA ps_end
    RTS
.endproc


.proc print_heading
    LDX ps_end
    LDA #MESSAGE_LEN + 2
    STA ps_buffer+0,X
    LDA #$21
    STA ps_buffer+1,X
    LDA #$E4
    STA ps_buffer+2,X

    LDY #0
    write_message:
        LDA message,Y
        STA ps_buffer+3,X
        INX
        INY
        CPY #MESSAGE_LEN
        BCC write_message

    LDA selected_problem
    CLC
    ADC #(1 << 1)
    LSR A
    STA ps_buffer+3,X
    LDA #$A
    ADC #0 ; if C was set, print B
    STA ps_buffer+4,X

    LDA #0
    STA ps_buffer+5,X

    TXA
    CLC
    ADC #5
    STA ps_end
    RTS

    message:
    .byte $1C, $18, $15, $1F, $0E, $37, $FF
    MESSAGE_LEN = (* - message)
.endproc


.proc draw_nametable
    logo_row_counter := vars+0

    LDA #$20
    STA ppuaddr
    LDA #$00
    STA ppuaddr

    ;;; Clear first 6 rows
    LDX #(32>>2)*6
    LDA #$FF
    JSR fill_ppudata_quads

    LDA #7
    STA logo_row_counter
    LDY #$50
    draw_logo_rows:
        LDX #1
        LDA #$FF
        JSR fill_ppudata_quads

        LDX #4
        draw_logo:
            STY ppudata
            INY
            STY ppudata
            INY
            STY ppudata
            INY
            STY ppudata
            INY
            DEX
            BNE draw_logo

        LDX #3
        LDA #$FF
        JSR fill_ppudata_quads

        DEC logo_row_counter
        BNE draw_logo_rows


    ;;; Clear remaining rows
    LDX #(32>>2)*17
    LDA #$FF
    JSR fill_ppudata_quads

    ;;; Draw attribute bytes
    LDX #(8>>2)*2
    LDA #$00
    JSR fill_ppudata_quads

    LDX #(8>>2)*1
    LDA #$50
    JSR fill_ppudata_quads

    LDX #(8>>2)*1
    LDA #$05
    JSR fill_ppudata_quads

    LDX #(8>>2)*4
    LDA #$00
    JSR fill_ppudata_quads

    ;;; Draw "2023!"
    LDA #$21
    STA ppuaddr
    LDA #$75
    STA ppuaddr
    LDY #$C0
    STY ppudata
    INY
    STY ppudata
    INY
    STY ppudata

    LDA #$21
    STA ppuaddr
    LDA #$95
    STA ppuaddr
    LDY #$D0
    STY ppudata
    INY
    STY ppudata
    INY
    STY ppudata
    RTS
.endproc


.proc fill_ppudata_quads
    fill:
        STA ppudata
        STA ppudata
        STA ppudata
        STA ppudata
        DEX
        BNE fill
    RTS
.endproc


