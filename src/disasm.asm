; ------------------------------------------------------------
; DISASSEMBLER COMMAND
; Syntax:
;   D
;   D start
;   D start end
;
; Default start is MEM.
; Default length is 12 instructions.
; MEM is updated to the next address after the disassembly.
; ------------------------------------------------------------
cmd_disasm:
    jsr advance_lineptr
    jsr next_token
    bcc dis_default

    jsr parse_word
    jsr copy_T0_R0

    jsr next_token
    bcc dis_one_param

    jsr parse_word
    jsr copy_T0_R1
    jmp dis_prepare_range

dis_default:
    jsr copy_MEM_R0

dis_one_param:
    jsr copy_R0_R1
    lda #12
    sta parm_count
    jmp dis_prepare_count

dis_prepare_range:
    jsr next_token
    bcc dis_range_ok
    jmp cmd_error

dis_prepare_count:
    jsr next_token
    bcc dis_count_ok
    jmp cmd_error

dis_count_ok:
    jsr copy_R0_R2

dis_loop_count:
    jsr check_abort
    bcs dis_abort
    jsr disasm_line
    bcs dis_done
    dec parm_count
    bne dis_loop_count
    jsr copy_R2_MEM
		clc
		rts

dis_range_ok:
    jsr copy_R0_R2

dis_loop_range:
    jsr check_abort
    bcs dis_abort

    jsr cmp_R2_R1
    bcc dis_do_line
    beq dis_do_line
    jmp dis_done

dis_do_line:
    jsr disasm_line
    bcs dis_done
    jmp dis_loop_range

dis_done:
    jsr copy_R2_MEM
		clc
		rts

dis_abort:
    jmp cmd_error
		
; ------------------------------------------------------------
; DISASSEMBLE ONE LINE
;
; Input
;   R2 = current PC
;
; Internal use
;   T0L = opcode
;   R3L = addressing mode
;   R3H = instruction length
;   T1  = pointer to mnemonic string
;
; Output
;   prints one disassembly line
;   advances R2 by instruction length
; ------------------------------------------------------------
disasm_line:
    jsr print_disasm_address

    ldy #0
    lda (R2L),y
    sta T0L
    tax

    lda mode_table,x
    sta R3L
    jsr get_oplen_from_mode
    sta R3H

    jsr get_mnemonic_id_x
    jsr get_mnemonic_ptr_id

    jsr print_disasm_bytes
    jsr print_space
    jsr print_space
    jsr print_mnemonic
    jsr print_operand
    jsr newline

    lda R3H
    jmp add_R2_A

print_disasm_address:
    lda R2H
    ldx R2L
    jsr print_hex16
    jsr print_space
    jmp print_space
		
; ------------------------------------------------------------
; PRINT RAW BYTES FIELD
; Shows 1..3 actual instruction bytes and pads to fixed width.
; R3H = instruction length
; ------------------------------------------------------------
print_disasm_bytes:
    ldy #0

pdb_real_loop:
    cpy R3H
    beq pdb_pad
    lda (R2L),y
    jsr print_hex8
    jsr print_space
    iny
    cpy #3
    bne pdb_real_loop
    rts

pdb_pad:
    cpy #3
    beq pdb_done
    lda #' '
    jsr putchar
    lda #' '
    jsr putchar
    jsr print_space
    iny
    jmp pdb_pad

pdb_done:
    rts

; ------------------------------------------------------------
; GAP BETWEEN BYTE FIELD AND MNEMONIC
; ------------------------------------------------------------
print_disasm_gap:
    jsr print_space
    jmp print_space

; ------------------------------------------------------------
; PRINT MNEMONIC
; T1 = pointer to zero-terminated mnemonic string
; ------------------------------------------------------------
print_mnemonic:
    lda T1L
    ldx T1H
    jsr print_str
    jmp print_space

; ------------------------------------------------------------
; PRINT OPERAND
; R3L = addressing mode
; R2  = current instruction address
; ------------------------------------------------------------
print_operand:
    lda R3L
    asl
    tax
    lda operand_vecs,x
    sta jmpvec
    inx
    lda operand_vecs,x
    sta jmpvec+1
    jmp (jmpvec)

; ------------------------------------------------------------
; ADDRESSING MODE FORMATTERS
; ------------------------------------------------------------
fmt_imp:
    rts

fmt_acc:
    lda #'A'
    jmp putchar

fmt_imm:
    lda #'#'
    jsr putchar
    lda #'$'
    jsr putchar
    ldy #1
    lda (R2L),y
    jmp print_hex8

fmt_zp:
    lda #'$'
    jsr putchar
    ldy #1
    lda (R2L),y
    jmp print_hex8

fmt_zpx:
    jsr fmt_zp
    lda #','
    jsr putchar
    lda #'X'
    jmp putchar

fmt_zpy:
    jsr fmt_zp
    lda #','
    jsr putchar
    lda #'Y'
    jmp putchar

fmt_abs:
    lda #'$'
    jsr putchar
    ldy #1
    lda (R2L),y
    tax
    iny
    lda (R2L),y
    jmp print_hex16

fmt_absx:
    jsr fmt_abs
    lda #','
    jsr putchar
    lda #'X'
    jmp putchar

fmt_absy:
    jsr fmt_abs
    lda #','
    jsr putchar
    lda #'Y'
    jmp putchar

fmt_ind:
    lda #'('
    jsr putchar
    jsr fmt_abs
    lda #')'
    jmp putchar

fmt_indx:
    lda #'('
    jsr putchar
    jsr fmt_zp
    lda #','
    jsr putchar
    lda #'X'
    jsr putchar
    lda #')'
    jmp putchar

fmt_indy:
    lda #'('
    jsr putchar
    jsr fmt_zp
    lda #')'
    jsr putchar
    lda #','
    jsr putchar
    lda #'Y'
    jmp putchar

fmt_zpind:
    lda #'('
    jsr putchar
    jsr fmt_zp
    lda #')'
    jmp putchar

fmt_rel:
    ldy #1
    lda (R2L),y
    sta T1L

    lda R2L
    clc
    adc #2
    sta T0L
    lda R2H
    adc #0
    sta T0H

    lda T1L
    bmi rel_neg

    clc
    adc T0L
    tax
    lda T0H
    adc #0
    jmp rel_print

rel_neg:
    clc
    adc T0L
    tax
    lda T0H
    adc #$FF

rel_print:
    pha
    lda #'$'
    jsr putchar
    pla
    jmp print_hex16

fmt_zprel:
    jsr fmt_zp
    lda #','
    jsr putchar

    ldy #2
    lda (R2L),y
    sta T1L

    lda R2L
    clc
    adc #3
    sta T0L
    lda R2H
    adc #0
    sta T0H

    lda T1L
    bmi zrel_neg

    clc
    adc T0L
    tax
    lda T0H
    adc #0
    jmp zrel_print

zrel_neg:
    clc
    adc T0L
    tax
    lda T0H
    adc #$FF

zrel_print:
    pha
    lda #'$'
    jsr putchar
    pla
    jmp print_hex16

fmt_aix:
    lda #'('
    jsr putchar
    jsr fmt_abs
    lda #','
    jsr putchar
    lda #'X'
    jsr putchar
    lda #')'
    jmp putchar

fmt_ill:
    lda #'.'
    jsr putchar
    lda #'b'
    jsr putchar
    lda #'y'
    jsr putchar
    lda #'t'
    jsr putchar
    lda #'e'
    jsr putchar
    jsr print_space
    lda #'$'
    jsr putchar
    lda T0L
    jmp print_hex8

operand_vecs:
    .word fmt_imp
    .word fmt_acc
    .word fmt_imm
    .word fmt_zp
    .word fmt_zpx
    .word fmt_zpy
    .word fmt_abs
    .word fmt_absx
    .word fmt_absy
    .word fmt_ind
    .word fmt_indx
    .word fmt_indy
    .word fmt_zpind
    .word fmt_rel
    .word fmt_zprel
    .word fmt_aix
    .word fmt_ill
		
