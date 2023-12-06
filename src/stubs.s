.global nmi_handler, reset_handler, irq_handler

.macro MAKE_LOBANK_STUB seg
    .segment seg
    INC bank_7_stub
    NOP
    NOP
    NOP
    .addr nmi_handler, bank_7_stub, irq_handler
.endmacro

MAKE_LOBANK_STUB "STUB0"
MAKE_LOBANK_STUB "STUB1"
MAKE_LOBANK_STUB "STUB2"
MAKE_LOBANK_STUB "STUB3"
MAKE_LOBANK_STUB "STUB4"
MAKE_LOBANK_STUB "STUB5"
MAKE_LOBANK_STUB "STUB6"

.segment "STUB7"
bank_7_stub:
INC bank_7_stub
JMP reset_handler
.addr nmi_handler, bank_7_stub, irq_handler
