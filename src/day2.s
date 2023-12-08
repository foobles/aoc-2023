.export solve_day2_part1
.globalzp vars
.global solution, print_dbyte_to_solution


game_no := vars+0
possible_game_sum := vars+1 ; 16 bits
data_ptr := vars+3
block_count := vars+5

NUM_RED = 12
NUM_GREEN = 13
NUM_BLUE = 14

.segment "CODE2"
.proc solve_day2_part1
    LDA #0
    STA game_no
    STA possible_game_sum+0
    STA possible_game_sum+1

    LDA #<input_data
    STA data_ptr+0
    LDA #>input_data
    STA data_ptr+1

    loop:
        INC game_no
        LDY #7 ; Skip the first 7 bytes of each line ("Game N:")
        LDA (data_ptr),Y
        BEQ loop_done
        JSR process_line
        JMP loop

    loop_done:

    LDA possible_game_sum+0
    LDX possible_game_sum+1
    JMP print_dbyte_to_solution
.endproc

.proc process_line
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
        ADC possible_game_sum+0
        STA possible_game_sum+0
        BCC :+
            INC possible_game_sum+1
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

input_data:
.incbin "input/day2.txt"
.byte $00 ; Sentinel