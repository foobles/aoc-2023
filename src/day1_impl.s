.global solution, set_bank
.globalzp vars

data_ptr := vars+0
high_digit := vars+2
low_digit := vars+3

.proc solve_day1_part1
    reset_data_ptr:
        LDA #<input_data
        STA data_ptr+0
        LDA #>input_data
        STA data_ptr+1

    compute_loop:
        LDY #0
        LDA (data_ptr),Y
        BEQ bank_done
        JSR process_line
        JMP compute_loop

    bank_done:
        INY
        LDA (data_ptr),Y
        BMI data_done
        JSR set_bank
        JMP reset_data_ptr

    data_done:
        RTS
.endproc


.proc process_line
    find_first_digit:
        LDA (data_ptr),Y
        INY
        SEC
        SBC #48 ; '0'
        CMP #10
        BCS find_first_digit ; loop if not a decimal digit

    first_digit_found:
        STA high_digit
        STA low_digit

    find_last_digit:
        LDA (data_ptr),Y
        INY
        CMP #$0A ; line break
        BEQ last_digit_found
        SBC #48 ; '0'
        CMP #10
        BCS find_last_digit ; loop if not a decimal digit
        STA low_digit
        BCC find_last_digit ; loop to try and find another digit

    last_digit_found:
        LDA low_digit
        CLC
        ADC solution+0
        CMP #10
        BCC :+
            SBC #10
        :
        STA solution+0

        LDX #1
        LDA high_digit
    carry_dec:
        ADC solution,X
        CMP #10
        BCC :+
            SBC #10
        :
        STA solution,X
        LDA #0
        INX
        BCS carry_dec

    add_data_ptr:
        TYA
        CLC
        ADC data_ptr+0
        STA data_ptr+0
        BCC :+
            INC data_ptr+1
        :
        LDY #0

        RTS
.endproc


