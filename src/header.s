;;; NES2.0 format
;;; MMC1 Mapper

.import __HEADER_SIZE__

PRG_PAGE_COUNT  = 8     ; 16 KiB per page
CHR_PAGE_COUNT  = 1     ; 8 KiB per page; 0 = CHR RAM
MAPPER_NO       = 1     ; MMC1

.segment "HEADER"
    .byte "NES", $1A
    .byte PRG_PAGE_COUNT
    .byte CHR_PAGE_COUNT
    .byte ((MAPPER_NO & $0F) << 4)
    .byte MAPPER_NO & $F0
    .res 8, $00


.assert __HEADER_SIZE__ = 16, lderror, "incorrect header size"