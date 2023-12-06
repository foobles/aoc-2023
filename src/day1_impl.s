.global solution, set_bank
.globalzp vars

data_ptr := vars+0
high_digit := vars+2
low_digit := vars+3

;;; Only used by part 2
scan_jump_addr := vars+4
line_buffer_len := vars+6
line_buffer := vars+7

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
        JSR process_line_part1
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


.proc solve_day1_part2
    reset_data_ptr:
        LDA #<input_data
        STA data_ptr+0
        LDA #>input_data
        STA data_ptr+1

    compute_loop:
        LDY #0
        LDA (data_ptr),Y
        BEQ bank_done
        JSR process_line_part2
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


.proc process_line_part1
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





.proc scan_six_seven
    CMP #'i'
    BNE :+
    LDA line_buffer+2,X
    CMP #'x'
    BNE scan_digit_f_ret
    LDY #6
    BNE scan_digit_f_ret

    :
    CMP #'e'
    BNE scan_digit_f_ret
    LDA line_buffer+2,X
    CMP #'v'
    BNE scan_digit_f_ret
    LDA line_buffer+3,X
    CMP #'e'
    BNE scan_digit_f_ret
    LDA line_buffer+4,X
    CMP #'n'
    BNE scan_digit_f_ret
    LDY #7
    BNE scan_digit_f_ret
.endproc

.proc scan_eight
    CMP #'i'
    BNE scan_digit_f_ret
    LDA line_buffer+2,X
    CMP #'g'
    BNE scan_digit_f_ret
    LDA line_buffer+3,X
    CMP #'h'
    BNE scan_digit_f_ret
    LDA line_buffer+4,X
    CMP #'t'
    BNE scan_digit_f_ret
    LDY #8
    BNE scan_digit_f_ret
.endproc

.proc process_line_part2
        LDX #$FF
    read_line:
        INX
        LDA (data_ptr),Y
        STA line_buffer,X
        INY
        CMP #$0A ; line break
        BNE read_line

    read_line_done:
        STX line_buffer_len
        TYA
        CLC
        ADC data_ptr+0
        STA data_ptr+0
        BCC :+
            INC data_ptr+1
        :

    ;;; Finding first digit
        LDX #$FF
    find_first_digit:
        INX ; X points to current character
        LDA line_buffer,X

        ;;; Check if ASCII digit
        SEC
        SBC #'0'
        CMP #10
        BCC first_digit_found

        ;;; Scan for words
        SBC #'a' - '0' ; We know C is set
        TAY
        LDA forward_scan_his,Y
        BEQ find_first_digit ; If zp then not digit
        STA scan_jump_addr+1
        LDA forward_scan_los,Y
        STA scan_jump_addr+0
        LDY #0
        LDA line_buffer+1,X
        JMP (scan_jump_addr) ; Scan for digit name
        scan_digit_f_ret:
        TYA
        BEQ find_first_digit

    first_digit_found:
        JMP process_line_part2_b
.endproc


scan_digit_f_ret := process_line_part2::scan_digit_f_ret

.proc scan_one
    CMP #'n'
    BNE scan_digit_f_ret
    LDA line_buffer+2,X
    CMP #'e'
    BNE scan_digit_f_ret
    LDY #1
    BNE scan_digit_f_ret
.endproc

.proc scan_two_three
    CMP #'w'
    BNE :+
    LDA line_buffer+2,X
    CMP #'o'
    BNE scan_digit_f_ret
    LDY #2
    BNE scan_digit_f_ret
    :
    CMP #'h'
    BNE scan_digit_f_ret
    LDA line_buffer+2,X
    CMP #'r'
    BNE scan_digit_f_ret
    LDA line_buffer+3,X
    CMP #'e'
    BNE scan_digit_f_ret
    LDA line_buffer+4,X
    CMP #'e'
    BNE scan_digit_f_ret
    LDY #3
    BNE scan_digit_f_ret
.endproc

.proc scan_four_five
    CMP #'o'
    BNE :+
    LDA line_buffer+2,X
    CMP #'u'
    BNE scan_digit_f_ret
    LDA line_buffer+3,X
    CMP #'r'
    BNE scan_digit_f_ret
    LDY #4
    BNE scan_digit_f_ret
    :
    CMP #'i'
    BNE scan_digit_f_ret
    LDA line_buffer+2,X
    CMP #'v'
    BNE scan_digit_f_ret
    LDA line_buffer+3,X
    CMP #'e'
    BNE scan_digit_f_ret
    LDY #5
    BNE scan_digit_f_ret
.endproc

.proc scan_nine
    CMP #'i'
    BNE scan_digit_f_ret
    LDA line_buffer+2,X
    CMP #'n'
    BNE scan_digit_f_ret
    LDA line_buffer+3,X
    CMP #'e'
    BNE scan_digit_f_ret
    LDY #9
    BNE scan_digit_f_ret
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.proc scan_thgie
    CMP #'h'
    BNE scan_digit_b_ret
    LDA line_buffer-2,X
    CMP #'g'
    BNE scan_digit_b_ret
    LDA line_buffer-3,X
    CMP #'i'
    BNE scan_digit_b_ret
    LDA line_buffer-4,X
    CMP #'e'
    BNE scan_digit_b_ret
    LDY #8
    BNE scan_digit_b_ret
.endproc

.proc scan_ruof
    CMP #'u'
    BNE scan_digit_b_ret
    LDA line_buffer-2,X
    CMP #'o'
    BNE scan_digit_b_ret
    LDA line_buffer-3,X
    CMP #'f'
    BNE scan_digit_b_ret
    LDY #4
    BNE scan_digit_b_ret
.endproc

.proc scan_xis
    CMP #'i'
    BNE scan_digit_b_ret
    LDA line_buffer-2,X
    CMP #'s'
    BNE scan_digit_b_ret
    LDY #6
    BNE scan_digit_b_ret
.endproc


.proc process_line_part2_b
    store_first_digit:
        STA high_digit

        LDX line_buffer_len
    find_last_digit:
        DEX
        LDA line_buffer,X

        ;;; Check if ASCII digit
        SEC
        SBC #'0'
        CMP #10
        BCC second_digit_found

        ;;; Scan for words
        SBC #'a' - '0' ; We know C is set
        TAY
        LDA backward_scan_his,Y
        BEQ find_last_digit ; If zp then not digit
        STA scan_jump_addr+1
        LDA backward_scan_los,Y
        STA scan_jump_addr+0
        LDY #0
        LDA line_buffer-1,X
        JMP (scan_jump_addr)
        scan_digit_b_ret:
        TYA
        BEQ find_last_digit

    second_digit_found:
        JMP process_line_part2_c
.endproc

scan_digit_b_ret := process_line_part2_b::scan_digit_b_ret

.proc scan_eno_eerht_evif_enin
    CMP #'n'
    BNE eerht_or_evif
    LDA line_buffer-2,X
    CMP #'o'
    BNE enin
    LDY #1
    BNE scan_digit_b_ret

    eerht_or_evif:
    CMP #'e'
    BNE evif
    LDA line_buffer-2,X
    CMP #'r'
    BNE scan_digit_b_ret
    LDA line_buffer-3,X
    CMP #'h'
    BNE scan_digit_b_ret
    LDA line_buffer-4,X
    CMP #'t'
    BNE scan_digit_b_ret
    LDY #3
    BNE scan_digit_b_ret

    evif:
    CMP #'v'
    BNE scan_digit_b_ret
    LDA line_buffer-2,X
    CMP #'i'
    BNE scan_digit_b_ret
    LDA line_buffer-3,X
    CMP #'f'
    BNE scan_digit_b_ret
    LDY #5
    BNE scan_digit_b_ret

    enin:
    CMP #'i'
    BNE scan_digit_b_ret
    LDA line_buffer-3,X
    CMP #'n'
    BNE scan_digit_b_ret
    LDY #9
    BNE scan_digit_b_ret
.endproc

.proc scan_owt
    CMP #'w'
    BNE scan_digit_b_ret
    LDA line_buffer-2,X
    CMP #'t'
    BNE scan_digit_b_ret
    LDY #2
    BNE scan_digit_b_ret
.endproc

.proc scan_neves
    CMP #'e'
    BNE scan_digit_b_ret
    LDA line_buffer-2,X
    CMP #'v'
    BNE scan_digit_b_ret
    LDA line_buffer-3,X
    CMP #'e'
    BNE scan_digit_b_ret
    LDA line_buffer-4,X
    CMP #'s'
    BNE scan_digit_b_ret
    LDY #7
    BNE scan_digit_b_ret
.endproc






.proc process_line_part2_c
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

        LDY #0
        RTS
.endproc

;;; one
;;; two
;;; three
;;; four
;;; five
;;; six
;;; seven
;;; eight
;;; nine

.align $100
forward_scan_his:
    .res 4, $00             ; abcd
    .byte >scan_eight       ; e
    .byte >scan_four_five   ; f
    .res 7, $00             ; ghijklm
    .byte >scan_nine        ; n
    .byte >scan_one         ; o
    .res 3, $00             ; pqr
    .byte >scan_six_seven   ; s
    .byte >scan_two_three   ; t
    .res 6, $00             ; uvwxyz

forward_scan_los:
    .res 4, $00             ; abcd
    .byte <scan_eight       ; e
    .byte <scan_four_five   ; f
    .res 7, $00             ; ghijklm
    .byte <scan_nine        ; n
    .byte <scan_one         ; o
    .res 3, $00             ; pqr
    .byte <scan_six_seven   ; s
    .byte <scan_two_three   ; t
    .res 6, $00             ; uvwxyz

;;; eno
;;; owt
;;; eerht
;;; ruof
;;; evif
;;; xis
;;; neves
;;; thgie
;;; enin

backward_scan_his:
    .res 4, $00                     ; abcd
    .byte >scan_eno_eerht_evif_enin ; e
    .res 8, $00                     ; fghijklm
    .byte >scan_neves               ; n
    .byte >scan_owt                 ; o
    .res 2, $00                     ; pq
    .byte >scan_ruof                ; r
    .res 1, $00                     ; s
    .byte >scan_thgie               ; t
    .res 3, $00                     ; uvw
    .byte >scan_xis                 ; x
    .res 2, $00                     ; yz

backward_scan_los:
    .res 4, $00                     ; abcd
    .byte <scan_eno_eerht_evif_enin ; e
    .res 8, $00                     ; fghijklm
    .byte <scan_neves               ; n
    .byte <scan_owt                 ; o
    .res 2, $00                     ; pq
    .byte <scan_ruof                ; r
    .res 1, $00                     ; s
    .byte <scan_thgie               ; t
    .res 3, $00                     ; uvw
    .byte <scan_xis                 ; x
    .res 2, $00                     ; yz
