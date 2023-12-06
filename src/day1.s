.export solve_day1_part1, solve_day1_part2
.global solution

.segment "CODE0"
.include "day1_impl.s"
input_data:
.incbin "input/day1_a.txt"
.byte $00, $01 ; sentinel + next bank to switch to

.segment "CODE1"
.scope ; use scope to prevent duplicate definitions
.include "day1_impl.s"
.endscope
.assert * = input_data, error
.incbin "input/day1_b.txt"
.byte $00, $FF ; sentinel + indicate done