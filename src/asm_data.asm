; asm_data.asm
; W65C02S (dis)assembler tables
;
; Data source:
; - WDC W65C02S opcode matrix
; - 16 addressing modes, 212 defined opcodes
;
; Undefined / blank matrix cells are mapped to:
;   mn_ILL / AM_ILL / length 1

; ------------------------------------------------------------
; Addressing mode IDs
; ------------------------------------------------------------

AM_IMP   = 0      ; implied / stack
AM_ACC   = 1      ; accumulator
AM_IMM   = 2      ; immediate
AM_ZP    = 3      ; zero page
AM_ZPX   = 4      ; zero page,X
AM_ZPY   = 5      ; zero page,Y
AM_ABS   = 6      ; absolute
AM_ABSX  = 7      ; absolute,X
AM_ABSY  = 8      ; absolute,Y
AM_IND   = 9      ; (absolute)
AM_INDX  = 10     ; (zp,X)
AM_INDY  = 11     ; (zp),Y
AM_ZPIND = 12     ; (zp)
AM_REL   = 13     ; relative
AM_ZPREL = 14     ; zp,relative   (BBR/BBS)
AM_AIX   = 15     ; (absolute,X)
AM_ILL   = 16     ; undefined / reserved

; ------------------------------------------------------------
; Unique mnemonic strings
; ------------------------------------------------------------

mn_ILL:  .byte ".DB",0

mn_ADC:  .byte "ADC",0
mn_AND:  .byte "AND",0
mn_ASL:  .byte "ASL",0
mn_BCC:  .byte "BCC",0
mn_BCS:  .byte "BCS",0
mn_BEQ:  .byte "BEQ",0
mn_BIT:  .byte "BIT",0
mn_BMI:  .byte "BMI",0
mn_BNE:  .byte "BNE",0
mn_BPL:  .byte "BPL",0
mn_BRA:  .byte "BRA",0
mn_BRK:  .byte "BRK",0
mn_BVC:  .byte "BVC",0
mn_BVS:  .byte "BVS",0
mn_CLC:  .byte "CLC",0
mn_CLD:  .byte "CLD",0
mn_CLI:  .byte "CLI",0
mn_CLV:  .byte "CLV",0
mn_CMP:  .byte "CMP",0
mn_CPX:  .byte "CPX",0
mn_CPY:  .byte "CPY",0
mn_DEC:  .byte "DEC",0
mn_DEX:  .byte "DEX",0
mn_DEY:  .byte "DEY",0
mn_EOR:  .byte "EOR",0
mn_INC:  .byte "INC",0
mn_INX:  .byte "INX",0
mn_INY:  .byte "INY",0
mn_JMP:  .byte "JMP",0
mn_JSR:  .byte "JSR",0
mn_LDA:  .byte "LDA",0
mn_LDX:  .byte "LDX",0
mn_LDY:  .byte "LDY",0
mn_LSR:  .byte "LSR",0
mn_NOP:  .byte "NOP",0
mn_ORA:  .byte "ORA",0
mn_PHA:  .byte "PHA",0
mn_PHP:  .byte "PHP",0
mn_PHX:  .byte "PHX",0
mn_PHY:  .byte "PHY",0
mn_PLA:  .byte "PLA",0
mn_PLP:  .byte "PLP",0
mn_PLX:  .byte "PLX",0
mn_PLY:  .byte "PLY",0
mn_ROL:  .byte "ROL",0
mn_ROR:  .byte "ROR",0
mn_RTI:  .byte "RTI",0
mn_RTS:  .byte "RTS",0
mn_SBC:  .byte "SBC",0
mn_SEC:  .byte "SEC",0
mn_SED:  .byte "SED",0
mn_SEI:  .byte "SEI",0
mn_STA:  .byte "STA",0
mn_STP:  .byte "STP",0
mn_STX:  .byte "STX",0
mn_STY:  .byte "STY",0
mn_STZ:  .byte "STZ",0
mn_TAX:  .byte "TAX",0
mn_TAY:  .byte "TAY",0
mn_TRB:  .byte "TRB",0
mn_TSB:  .byte "TSB",0
mn_TSX:  .byte "TSX",0
mn_TXA:  .byte "TXA",0
mn_TXS:  .byte "TXS",0
mn_TYA:  .byte "TYA",0
mn_WAI:  .byte "WAI",0

mn_RMB0: .byte "RMB0",0
mn_RMB1: .byte "RMB1",0
mn_RMB2: .byte "RMB2",0
mn_RMB3: .byte "RMB3",0
mn_RMB4: .byte "RMB4",0
mn_RMB5: .byte "RMB5",0
mn_RMB6: .byte "RMB6",0
mn_RMB7: .byte "RMB7",0

mn_SMB0: .byte "SMB0",0
mn_SMB1: .byte "SMB1",0
mn_SMB2: .byte "SMB2",0
mn_SMB3: .byte "SMB3",0
mn_SMB4: .byte "SMB4",0
mn_SMB5: .byte "SMB5",0
mn_SMB6: .byte "SMB6",0
mn_SMB7: .byte "SMB7",0

mn_BBR0: .byte "BBR0",0
mn_BBR1: .byte "BBR1",0
mn_BBR2: .byte "BBR2",0
mn_BBR3: .byte "BBR3",0
mn_BBR4: .byte "BBR4",0
mn_BBR5: .byte "BBR5",0
mn_BBR6: .byte "BBR6",0
mn_BBR7: .byte "BBR7",0

mn_BBS0: .byte "BBS0",0
mn_BBS1: .byte "BBS1",0
mn_BBS2: .byte "BBS2",0
mn_BBS3: .byte "BBS3",0
mn_BBS4: .byte "BBS4",0
mn_BBS5: .byte "BBS5",0
mn_BBS6: .byte "BBS6",0
mn_BBS7: .byte "BBS7",0

; ------------------------------------------------------------
; Addressing mode table
; Blank / reserved cells are AM_ILL.
; ------------------------------------------------------------

mode_table:
    .byte AM_IMP, AM_INDX, AM_ILL,   AM_ILL,   AM_ZP,   AM_ZP,   AM_ZP,   AM_ZP,   AM_IMP,  AM_IMM, AM_ACC, AM_ILL, AM_ABS,  AM_ABS,  AM_ABS,  AM_ZPREL
    .byte AM_REL, AM_INDY, AM_ZPIND, AM_ILL,   AM_ZP,   AM_ZPX,  AM_ZPX,  AM_ZP,   AM_IMP,  AM_ABSY,AM_ACC, AM_ILL, AM_ABS,  AM_ABSX, AM_ABSX, AM_ZPREL
    .byte AM_ABS, AM_INDX, AM_ILL,   AM_ILL,   AM_ZP,   AM_ZP,   AM_ZP,   AM_ZP,   AM_IMP,  AM_IMM, AM_ACC, AM_ILL, AM_ABS,  AM_ABS,  AM_ABS,  AM_ZPREL
    .byte AM_REL, AM_INDY, AM_ZPIND, AM_ILL,   AM_ZPX,  AM_ZPX,  AM_ZPX,  AM_ZP,   AM_IMP,  AM_ABSY,AM_ACC, AM_ILL, AM_ABSX, AM_ABSX, AM_ABSX, AM_ZPREL

    .byte AM_IMP, AM_INDX, AM_ILL,   AM_ILL,   AM_ILL,  AM_ZP,   AM_ZP,   AM_ZP,   AM_IMP,  AM_IMM, AM_ACC, AM_ILL, AM_ABS,  AM_ABS,  AM_ABS,  AM_ZPREL
    .byte AM_REL, AM_INDY, AM_ZPIND, AM_ILL,   AM_ILL,  AM_ZPX,  AM_ZPX,  AM_ZP,   AM_IMP,  AM_ABSY,AM_IMP, AM_ILL, AM_ILL,  AM_ABSX, AM_ABSX, AM_ZPREL
    .byte AM_IMP, AM_INDX, AM_ILL,   AM_ILL,   AM_ZP,   AM_ZP,   AM_ZP,   AM_ZP,   AM_IMP,  AM_IMM, AM_ACC, AM_ILL, AM_IND,  AM_ABS,  AM_ABS,  AM_ZPREL
    .byte AM_REL, AM_INDY, AM_ZPIND, AM_ILL,   AM_ZPX,  AM_ZPX,  AM_ZPX,  AM_ZP,   AM_IMP,  AM_ABSY,AM_IMP, AM_ILL, AM_AIX,  AM_ABSX, AM_ABSX, AM_ZPREL

    .byte AM_REL, AM_INDX, AM_ILL,   AM_ILL,   AM_ZP,   AM_ZP,   AM_ZP,   AM_ZP,   AM_IMP,  AM_IMM, AM_IMP, AM_ILL, AM_ABS,  AM_ABS,  AM_ABS,  AM_ZPREL
    .byte AM_REL, AM_INDY, AM_ZPIND, AM_ILL,   AM_ZPX,  AM_ZPX,  AM_ZPY,  AM_ZP,   AM_IMP,  AM_ABSY,AM_IMP, AM_ILL, AM_ABS,  AM_ABSX, AM_ABSX, AM_ZPREL
    .byte AM_IMM, AM_INDX, AM_IMM,   AM_ILL,   AM_ZP,   AM_ZP,   AM_ZP,   AM_ZP,   AM_IMP,  AM_IMM, AM_IMP, AM_ILL, AM_ABS,  AM_ABS,  AM_ABS,  AM_ZPREL
    .byte AM_REL, AM_INDY, AM_ZPIND, AM_ILL,   AM_ZPX,  AM_ZPX,  AM_ZPY,  AM_ZP,   AM_IMP,  AM_ABSY,AM_IMP, AM_ILL, AM_ABSX, AM_ABSX, AM_ABSY, AM_ZPREL

    .byte AM_IMM, AM_INDX, AM_ILL,   AM_ILL,   AM_ZP,   AM_ZP,   AM_ZP,   AM_ZP,   AM_IMP,  AM_IMM, AM_IMP, AM_IMP, AM_ABS,  AM_ABS,  AM_ABS,  AM_ZPREL
    .byte AM_REL, AM_INDY, AM_ZPIND, AM_ILL,   AM_ILL,  AM_ZPX,  AM_ZPX,  AM_ZP,   AM_IMP,  AM_ABSY,AM_IMP, AM_IMP, AM_ILL,  AM_ABSX, AM_ABSX, AM_ZPREL
    .byte AM_IMM, AM_INDX, AM_ILL,   AM_ILL,   AM_ZP,   AM_ZP,   AM_ZP,   AM_ZP,   AM_IMP,  AM_IMM, AM_IMP, AM_ILL, AM_ABS,  AM_ABS,  AM_ABS,  AM_ZPREL
    .byte AM_REL, AM_INDY, AM_ZPIND, AM_ILL,   AM_ILL,  AM_ZPX,  AM_ZPX,  AM_ZP,   AM_IMP,  AM_ABSY,AM_IMP, AM_ILL, AM_ILL,  AM_ABSX, AM_ABSX, AM_ZPREL

; ------------------------------------------------------------
; Mnemonic IDs
; Order must match mnemonic_text_ptrs below.
; ------------------------------------------------------------

MN_ILL   = 0
MN_ADC   = 1
MN_AND   = 2
MN_ASL   = 3
MN_BCC   = 4
MN_BCS   = 5
MN_BEQ   = 6
MN_BIT   = 7
MN_BMI   = 8
MN_BNE   = 9
MN_BPL   = 10
MN_BRA   = 11
MN_BRK   = 12
MN_BVC   = 13
MN_BVS   = 14
MN_CLC   = 15
MN_CLD   = 16
MN_CLI   = 17
MN_CLV   = 18
MN_CMP   = 19
MN_CPX   = 20
MN_CPY   = 21
MN_DEC   = 22
MN_DEX   = 23
MN_DEY   = 24
MN_EOR   = 25
MN_INC   = 26
MN_INX   = 27
MN_INY   = 28
MN_JMP   = 29
MN_JSR   = 30
MN_LDA   = 31
MN_LDX   = 32
MN_LDY   = 33
MN_LSR   = 34
MN_NOP   = 35
MN_ORA   = 36
MN_PHA   = 37
MN_PHP   = 38
MN_PHX   = 39
MN_PHY   = 40
MN_PLA   = 41
MN_PLP   = 42
MN_PLX   = 43
MN_PLY   = 44
MN_ROL   = 45
MN_ROR   = 46
MN_RTI   = 47
MN_RTS   = 48
MN_SBC   = 49
MN_SEC   = 50
MN_SED   = 51
MN_SEI   = 52
MN_STA   = 53
MN_STP   = 54
MN_STX   = 55
MN_STY   = 56
MN_STZ   = 57
MN_TAX   = 58
MN_TAY   = 59
MN_TRB   = 60
MN_TSB   = 61
MN_TSX   = 62
MN_TXA   = 63
MN_TXS   = 64
MN_TYA   = 65
MN_WAI   = 66
MN_RMB0  = 67
MN_RMB1  = 68
MN_RMB2  = 69
MN_RMB3  = 70
MN_RMB4  = 71
MN_RMB5  = 72
MN_RMB6  = 73
MN_RMB7  = 74
MN_SMB0  = 75
MN_SMB1  = 76
MN_SMB2  = 77
MN_SMB3  = 78
MN_SMB4  = 79
MN_SMB5  = 80
MN_SMB6  = 81
MN_SMB7  = 82
MN_BBR0  = 83
MN_BBR1  = 84
MN_BBR2  = 85
MN_BBR3  = 86
MN_BBR4  = 87
MN_BBR5  = 88
MN_BBR6  = 89
MN_BBR7  = 90
MN_BBS0  = 91
MN_BBS1  = 92
MN_BBS2  = 93
MN_BBS3  = 94
MN_BBS4  = 95
MN_BBS5  = 96
MN_BBS6  = 97
MN_BBS7  = 98

;
; instruction length lookup table
;
mode_len_table:
    .byte 1  ; AM_IMP
    .byte 1  ; AM_ACC
    .byte 2  ; AM_IMM
    .byte 2  ; AM_ZP
    .byte 2  ; AM_ZPX
    .byte 2  ; AM_ZPY
    .byte 3  ; AM_ABS
    .byte 3  ; AM_ABSX
    .byte 3  ; AM_ABSY
    .byte 3  ; AM_IND
    .byte 2  ; AM_INDX
    .byte 2  ; AM_INDY
    .byte 2  ; AM_ZPIND
    .byte 2  ; AM_REL
    .byte 3  ; AM_ZPREL
    .byte 3  ; AM_AIX
    .byte 1  ; AM_ILL
		
; ------------------------------------------------------------
; Unique mnemonic pointer table
; Indexed by mnemonic ID.
; ------------------------------------------------------------

mnemonic_text_ptrs:
    .word mn_ILL, mn_ADC, mn_AND, mn_ASL, mn_BCC, mn_BCS, mn_BEQ, mn_BIT
    .word mn_BMI, mn_BNE, mn_BPL, mn_BRA, mn_BRK, mn_BVC, mn_BVS, mn_CLC
    .word mn_CLD, mn_CLI, mn_CLV, mn_CMP, mn_CPX, mn_CPY, mn_DEC, mn_DEX
    .word mn_DEY, mn_EOR, mn_INC, mn_INX, mn_INY, mn_JMP, mn_JSR, mn_LDA
    .word mn_LDX, mn_LDY, mn_LSR, mn_NOP, mn_ORA, mn_PHA, mn_PHP, mn_PHX
    .word mn_PHY, mn_PLA, mn_PLP, mn_PLX, mn_PLY, mn_ROL, mn_ROR, mn_RTI
    .word mn_RTS, mn_SBC, mn_SEC, mn_SED, mn_SEI, mn_STA, mn_STP, mn_STX
    .word mn_STY, mn_STZ, mn_TAX, mn_TAY, mn_TRB, mn_TSB, mn_TSX, mn_TXA
    .word mn_TXS, mn_TYA, mn_WAI, mn_RMB0, mn_RMB1, mn_RMB2, mn_RMB3, mn_RMB4
    .word mn_RMB5, mn_RMB6, mn_RMB7, mn_SMB0, mn_SMB1, mn_SMB2, mn_SMB3, mn_SMB4
    .word mn_SMB5, mn_SMB6, mn_SMB7, mn_BBR0, mn_BBR1, mn_BBR2, mn_BBR3, mn_BBR4
    .word mn_BBR5, mn_BBR6, mn_BBR7, mn_BBS0, mn_BBS1, mn_BBS2, mn_BBS3, mn_BBS4
    .word mn_BBS5, mn_BBS6, mn_BBS7

; ------------------------------------------------------------
; Opcode -> mnemonic ID table
; Replaces mnemonic_ptrs.
; ------------------------------------------------------------

mnemonic_id_table:
    .byte MN_BRK, MN_ORA, MN_ILL, MN_ILL, MN_TSB, MN_ORA, MN_ASL, MN_RMB0, MN_PHP, MN_ORA, MN_ASL, MN_ILL, MN_TSB, MN_ORA, MN_ASL, MN_BBR0
    .byte MN_BPL, MN_ORA, MN_ORA, MN_ILL, MN_TRB, MN_ORA, MN_ASL, MN_RMB1, MN_CLC, MN_ORA, MN_INC, MN_ILL, MN_TRB, MN_ORA, MN_ASL, MN_BBR1
    .byte MN_JSR, MN_AND, MN_ILL, MN_ILL, MN_BIT, MN_AND, MN_ROL, MN_RMB2, MN_PLP, MN_AND, MN_ROL, MN_ILL, MN_BIT, MN_AND, MN_ROL, MN_BBR2
    .byte MN_BMI, MN_AND, MN_AND, MN_ILL, MN_BIT, MN_AND, MN_ROL, MN_RMB3, MN_SEC, MN_AND, MN_DEC, MN_ILL, MN_BIT, MN_AND, MN_ROL, MN_BBR3
    .byte MN_RTI, MN_EOR, MN_ILL, MN_ILL, MN_ILL, MN_EOR, MN_LSR, MN_RMB4, MN_PHA, MN_EOR, MN_LSR, MN_ILL, MN_JMP, MN_EOR, MN_LSR, MN_BBR4
    .byte MN_BVC, MN_EOR, MN_EOR, MN_ILL, MN_ILL, MN_EOR, MN_LSR, MN_RMB5, MN_CLI, MN_EOR, MN_PHY, MN_ILL, MN_ILL, MN_EOR, MN_LSR, MN_BBR5
    .byte MN_RTS, MN_ADC, MN_ILL, MN_ILL, MN_STZ, MN_ADC, MN_ROR, MN_RMB6, MN_PLA, MN_ADC, MN_ROR, MN_ILL, MN_JMP, MN_ADC, MN_ROR, MN_BBR6
    .byte MN_BVS, MN_ADC, MN_ADC, MN_ILL, MN_STZ, MN_ADC, MN_ROR, MN_RMB7, MN_SEI, MN_ADC, MN_PLY, MN_ILL, MN_JMP, MN_ADC, MN_ROR, MN_BBR7
    .byte MN_BRA, MN_STA, MN_ILL, MN_ILL, MN_STY, MN_STA, MN_STX, MN_SMB0, MN_DEY, MN_BIT, MN_TXA, MN_ILL, MN_STY, MN_STA, MN_STX, MN_BBS0
    .byte MN_BCC, MN_STA, MN_STA, MN_ILL, MN_STY, MN_STA, MN_STX, MN_SMB1, MN_TYA, MN_STA, MN_TXS, MN_ILL, MN_STZ, MN_STA, MN_STZ, MN_BBS1
    .byte MN_LDY, MN_LDA, MN_LDX, MN_ILL, MN_LDY, MN_LDA, MN_LDX, MN_SMB2, MN_TAY, MN_LDA, MN_TAX, MN_ILL, MN_LDY, MN_LDA, MN_LDX, MN_BBS2
    .byte MN_BCS, MN_LDA, MN_LDA, MN_ILL, MN_LDY, MN_LDA, MN_LDX, MN_SMB3, MN_CLV, MN_LDA, MN_TSX, MN_ILL, MN_LDY, MN_LDA, MN_LDX, MN_BBS3
    .byte MN_CPY, MN_CMP, MN_ILL, MN_ILL, MN_CPY, MN_CMP, MN_DEC, MN_SMB4, MN_INY, MN_CMP, MN_DEX, MN_WAI, MN_CPY, MN_CMP, MN_DEC, MN_BBS4
    .byte MN_BNE, MN_CMP, MN_CMP, MN_ILL, MN_ILL, MN_CMP, MN_DEC, MN_SMB5, MN_CLD, MN_CMP, MN_PHX, MN_STP, MN_ILL, MN_CMP, MN_DEC, MN_BBS5
    .byte MN_CPX, MN_SBC, MN_ILL, MN_ILL, MN_CPX, MN_SBC, MN_INC, MN_SMB6, MN_INX, MN_SBC, MN_NOP, MN_ILL, MN_CPX, MN_SBC, MN_INC, MN_BBS6
    .byte MN_BEQ, MN_SBC, MN_SBC, MN_ILL, MN_ILL, MN_SBC, MN_INC, MN_SMB7, MN_SED, MN_SBC, MN_PLX, MN_ILL, MN_ILL, MN_SBC, MN_INC, MN_BBS7
