.linecont +

.include "ppu_inc.s"
.include "input_inc.s"

.global nmi_handler, reset_handler, irq_handler, solution, set_bank
.globalzp vars, joy1_pressed

.import poll_input
.import solve_day1_part1

.segment "CHARS0"
.incbin "chr0.chr"

.segment "CHARS1"
.incbin "chr1.chr"

ps_buffer := $100

.zeropage
    vars: .res 16
    local_ppumask: .res 1
    local_ppuctrl: .res 1
    frame_done: .res 1
    computation_queued: .res 1
    ps_end: .res 1

    selected_problem: .res 1

.bss
    .align $100
    local_oam: .res $100
    solution: .res 16


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
        STA ppuctrl
        JMP (jump_addr)

    solution_ret:
        LDA local_ppuctrl
        STA ppuctrl
        JMP print_solution
.endproc

NUM_SOLUTIONS = 1
.define SOLUTION_ROUTINES \
    solve_day1_part1
solution_routine_los: .lobytes SOLUTION_ROUTINES
solution_routine_his: .hibytes SOLUTION_ROUTINES
solution_banks: .byte $00


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
    LDX ps_end

    LDY #17
    find_high_digit:
        DEY
        LDA solution-1,Y
        BEQ find_high_digit

    TYA
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
        BPL print_digits
    LDA #0
    STA ps_buffer+3,X
    TAX
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


