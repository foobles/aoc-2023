.export solve_day2_part1, solve_day2_part2
.globalzp vars, mul_out
.global solution, print_dbyte_to_solution, print_tbyte_to_solution, mul_u8_u8_u16


game_no := vars+0
game_sum := vars+1 ; day 1: 16 bits; day 2: 24 bits
data_ptr := vars+4
block_count := vars+6

;;; Only used in day 2
max_red := vars+7
max_green := vars+8
max_blue := vars+9
temp_mul_out := vars+10 ; 16 bits

;;; Only used in day 1
NUM_RED = 12
NUM_GREEN = 13
NUM_BLUE = 14

.segment "CODE2"
.proc solve_day2_part1
    LDA #0
    STA game_no
    STA game_sum+0
    STA game_sum+1

    LDA #<input_data
    STA data_ptr+0
    LDA #>input_data
    STA data_ptr+1

    loop:
        INC game_no
        LDY #7 ; Skip the first 7 bytes of each line ("Game N:")
        LDA (data_ptr),Y
        BEQ loop_done
        JSR process_line_day1
        JMP loop

    loop_done:

    LDA game_sum+0
    LDX game_sum+1
    JMP print_dbyte_to_solution
.endproc

.proc process_line_day1
    find_first_game:
        LDA (data_ptr),Y
        INY
        CMP #' '
        BNE find_first_game

    ;;; Y now points to first game
    loop:
        LDA (data_ptr),Y
        INY
        SEC
        SBC #'0'
        STA block_count
        TAX
        LDA (data_ptr),Y
        INY
        SBC #'0' ; We know C is set because previous must be digit
        BCC num_found ; If < '0', then must be a space. So we are done
        TAX ; Store 2nd digit in X

        ;;; Multiply first digit by 10
        LDA block_count
        ASL A
        ASL A
        ADC block_count ; ASL on number <10 guarantees C=0
        ASL A

        ;;; Add low digit (X) and high digit (A)
        STX block_count
        ADC block_count ; Ditto; C=0
        ;;; STA block_count ; Not used anymore
        TAX

        ;;; We know after 2 digits that the next character must be a space
        INY ; Skip the space
    num_found:
        ;;; X contains block count
        LDA (data_ptr),Y
        INY
        CMP #'b'
        BEQ process_blue
        CMP #'g'
        BEQ process_green

    process_red:
        INY ; skip 'e'
        INY ; skip 'd'
        CPX #NUM_RED+1
        BCS game_not_ok
        BCC check_loop_done ; BRA

    process_blue:
        INY ; skip 'l'
        INY ; skip 'u'
        INY ; skip 'e'
        CPX #NUM_BLUE+1
        BCS game_not_ok
        BCC check_loop_done ; BRA

    process_green:
        INY ; skip 'r'
        INY ; skip 'e'
        INY ; skip 'e'
        INY ; skip 'n'
        CPX #NUM_GREEN+1
        BCS game_not_ok

    check_loop_done:
        LDA (data_ptr),Y
        INY
        ;;; Check if character is newline
        CMP #$0A
        BEQ game_ok
        ;;; If not, must be a ',' or ';' followed by a space
        INY ; Skip space
        BNE loop ; BRA

    game_ok:
        LDA game_no
        CLC
        ADC game_sum+0
        STA game_sum+0
        BCC :+
            INC game_sum+1
        :

    add_data_ptr:
        TYA
        CLC
        ADC data_ptr+0
        STA data_ptr+0
        BCC :+
            INC data_ptr+1
        :

        RTS

    game_not_ok:
        LDA (data_ptr),Y
        INY
        CMP #$0A
        BEQ add_data_ptr
        BNE game_not_ok ; BRA
.endproc


.proc solve_day2_part2
    LDA #0
    STA game_no
    STA game_sum+0
    STA game_sum+1
    STA game_sum+2

    LDA #<input_data
    STA data_ptr+0
    LDA #>input_data
    STA data_ptr+1

    loop:
        INC game_no
        LDY #7 ; Skip the first 7 bytes of each line ("Game N:")
        LDA (data_ptr),Y
        BEQ loop_done
        JSR process_line_day2
        JMP loop

    loop_done:

    LDA game_sum+0
    LDX game_sum+1
    LDY game_sum+2
    JMP print_tbyte_to_solution
.endproc


.proc process_line_day2
    LDA #0
    STA max_red
    STA max_green
    STA max_blue

    find_first_game:
        LDA (data_ptr),Y
        INY
        CMP #' '
        BNE find_first_game

    ;;; Y now points to first game
    loop:
        LDA (data_ptr),Y
        INY
        SEC
        SBC #'0'
        STA block_count
        TAX
        LDA (data_ptr),Y
        INY
        SBC #'0' ; We know C is set because previous must be digit
        BCC num_found ; If < '0', then must be a space. So we are done
        TAX ; Store 2nd digit in X

        ;;; Multiply first digit by 10
        LDA block_count
        ASL A
        ASL A
        ADC block_count ; ASL on number <10 guarantees C=0
        ASL A

        ;;; Add low digit (X) and high digit (A)
        STX block_count
        ADC block_count ; Ditto; C=0
        ;;; STA block_count ; Not used anymore
        TAX

        ;;; We know after 2 digits that the next character must be a space
        INY ; Skip the space
    num_found:
        ;;; X contains block count
        LDA (data_ptr),Y
        INY
        CMP #'b'
        BEQ process_blue
        CMP #'g'
        BEQ process_green

    process_red:
        INY ; skip 'e'
        INY ; skip 'd'
        CPX max_red
        BCC check_loop_done
        STX max_red
        BCS check_loop_done ; BRA

    process_blue:
        INY ; skip 'l'
        INY ; skip 'u'
        INY ; skip 'e'
        CPX max_blue
        BCC check_loop_done
        STX max_blue
        BCS check_loop_done ; BRA

    process_green:
        INY ; skip 'r'
        INY ; skip 'e'
        INY ; skip 'e'
        INY ; skip 'n'
        CPX max_green
        BCC check_loop_done
        STX max_green

    check_loop_done:
        LDA (data_ptr),Y
        INY
        ;;; Check if character is newline
        CMP #$0A
        BEQ game_ok
        ;;; If not, must be a ',' or ';' followed by a space
        INY ; Skip space
        BNE loop ; BRA

    game_ok:
        ;;; Compute power of the game and add to game_sum (dear god)
        LDA max_red
        LDX max_green
        JSR mul_u8_u8_u16
        LDA mul_out+0
        STA temp_mul_out+0

        LDA mul_out+1
        LDX max_blue
        JSR mul_u8_u8_u16
        LDA mul_out+0
        CLC
        ADC game_sum+1
        STA game_sum+1

        LDA temp_mul_out+0
        LDX max_blue
        JSR mul_u8_u8_u16
        LDA mul_out+0
        CLC
        ADC game_sum+0
        STA game_sum+0
        LDA mul_out+1
        ADC game_sum+1
        STA game_sum+1

        BCC :+
            INC game_sum+2
        :

    add_data_ptr:
        TYA
        CLC
        ADC data_ptr+0
        STA data_ptr+0
        BCC :+
            INC data_ptr+1
        :

        RTS
.endproc

input_data:
.incbin "input/day2.txt"
.byte $00 ; Sentinel