.export solve_day1_part1
.global solution

.segment "CODE0"
.include "day1_impl.s"
input_data:
.incbin "day1_input_a.txt"
.byte $00, $01

.segment "CODE1"
.scope ; use scope to prevent duplicate definitions
.include "day1_impl.s"
.endscope
.assert * = input_data, error
.incbin "day1_input_b.txt"
.byte $00, $FF