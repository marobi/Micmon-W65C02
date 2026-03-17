; ------------------------------------------------------------
; SIMPLE ASSEMBLER COMMAND
; Syntax:
;   A [addr] mnemonic [operand]
;
; If addr is omitted, MEM is used.
; On success MEM is updated to the next address.
; ------------------------------------------------------------
cmd_asm:
    jsr advance_lineptr
    jsr next_token
    bcs ca_have_first
    jmp cmd_error

ca_have_first:
    ldy #0
    lda (lineptr),y
    jsr toupper
    cmp #'A'
    bcc ca_with_addr
    cmp #'Z'+1
    bcc ca_default_addr

ca_with_addr:
    jsr parse_word
    jsr copy_T0_R0
    jsr next_token
    bcs ca_mnemonic
    jmp cmd_error

ca_default_addr:
    jsr copy_MEM_R0

ca_mnemonic:
    jsr copy_R0_R2
    jsr parse_mnemonic
    jsr parse_asm_operand
    jsr next_token
    bcc ca_find
    jmp cmd_error

ca_find:
    jsr find_opcode
    bcs ca_emit
    jmp cmd_error

ca_emit:
    jmp emit_instruction
		
; ------------------------------------------------------------
; PARSE MNEMONIC
; lineptr must point at the first mnemonic character.
; Saves start pointer in R1 and length in mnem_len.
; Advances lineptr to the first character after the mnemonic.
; ------------------------------------------------------------
parse_mnemonic:
    jsr skip_spaces
    lda lineptr
    sta R1L
    lda lineptr+1
    sta R1H
    stz mnem_len

pm_loop:
    ldy #0
    lda (lineptr),y
    beq pm_done
    cmp #' '
    beq pm_done
    inc mnem_len
    jsr advance_lineptr
    jmp pm_loop

pm_done:
    lda mnem_len
    bne pm_ok
    jmp cmd_error

pm_ok:
    rts

; ------------------------------------------------------------
; COMPARE INPUT MNEMONIC AGAINST CANDIDATE STRING
; Input:
;   R1 = input mnemonic start
;   mnem_len = input mnemonic length
;   T1 = candidate zero-terminated mnemonic pointer
;
; Output:
;   C = 1 match
;   C = 0 no match
; ------------------------------------------------------------
compare_mnemonic:
    ldy #0

cm_loop:
    cpy mnem_len
    beq cm_end_input

    lda (R1L),y
    jsr toupper
    sta tmp

    lda (T1L),y
    beq cm_no
    cmp tmp
    bne cm_no

    iny
    jmp cm_loop

cm_end_input:
    lda (T1L),y
    beq cm_yes

cm_no:
    clc
    rts

cm_yes:
    sec
    rts


; ------------------------------------------------------------
; FETCH MNEMONIC ID FOR OPCODE IN X
; Uses mnemonic_id_table as a 256-byte table.
;
; Output:
;   A = mnemonic ID
; Preserves X
; ------------------------------------------------------------
get_mnemonic_id_x:
    lda mnemonic_id_table,x
    rts

; ------------------------------------------------------------
; FETCH MNEMONIC POINTER FOR MNEMONIC ID IN A
; Uses mnemonic_text_ptrs as a compact unique-pointer table.
;
; Input:
;   A = mnemonic ID
;
; Output:
;   T1 = pointer to zero-terminated mnemonic string
; Preserves X
; ------------------------------------------------------------
get_mnemonic_ptr_id:
    phx

    sta tmp
    asl
    tax

    lda mnemonic_text_ptrs,x
    sta T1L
    inx
    lda mnemonic_text_ptrs,x
    sta T1H

    plx
    rts

; ------------------------------------------------------------
; GET INSTRUCTION LENGTH FROM ADDRESSING MODE
;
; Input:
;   A = addressing mode
;
; Output:
;   A = instruction length
;
; Notes:
;   AM_IMP, AM_ACC, AM_ILL      -> 1
;   AM_IMM, AM_ZP, AM_ZPX,
;   AM_ZPY, AM_INDX, AM_INDY,
;   AM_ZPIND, AM_REL            -> 2
;   AM_ABS, AM_ABSX, AM_ABSY,
;   AM_IND, AM_ZPREL, AM_AIX    -> 3
; ------------------------------------------------------------
get_oplen_from_mode:
    cmp #AM_IMP
    beq gol_len1
    cmp #AM_ACC
    beq gol_len1
    cmp #AM_ILL
    beq gol_len1

    cmp #AM_IMM
    beq gol_len2
    cmp #AM_ZP
    beq gol_len2
    cmp #AM_ZPX
    beq gol_len2
    cmp #AM_ZPY
    beq gol_len2
    cmp #AM_INDX
    beq gol_len2
    cmp #AM_INDY
    beq gol_len2
    cmp #AM_ZPIND
    beq gol_len2
    cmp #AM_REL
    beq gol_len2

    lda #3
    rts

gol_len2:
    lda #2
    rts

gol_len1:
    lda #1
    rts
		
; ------------------------------------------------------------
; PARSE ASSEMBLER OPERAND
;
; Output:
;   asm_mode = parsed addressing mode
;   T0       = primary operand value
;   T1L      = zp byte for ZPREL
;
; Supported:
;   implied
;   A
;   #imm
;   zp / abs
;   zp,X / abs,X
;   zp,Y / abs,Y
;   (zp)
;   (abs)
;   (zp,X)
;   (abs,X)
;   (zp),Y
;   zp,target   (for BBR/BBS)
; ------------------------------------------------------------
parse_asm_operand:
    jsr next_token
    bcs pa_have_operand
    lda #AM_IMP
    sta asm_mode
    rts

pa_have_operand:
    ldy #0
    lda (lineptr),y
    cmp #'#'
    beq pa_imm
    cmp #'('
    beq pa_paren

    ; bare A can mean accumulator, but only if it is exactly "A"
    jsr toupper
    cmp #'A'
    beq pa_have_a
		jmp pa_value
		
pa_have_a:
    ldy #1
    lda (lineptr),y
    beq pa_try_acc
    cmp #' '
    beq pa_try_acc
    jmp pa_value

pa_try_acc:
    jsr advance_lineptr
    jsr next_token
    bcc pa_acc
    jmp cmd_error

pa_acc:
    lda #AM_ACC
    sta asm_mode
    rts

pa_imm:
    jsr advance_lineptr
    jsr parse_byte
    lda #AM_IMM
    sta asm_mode
    rts

pa_paren:
    jsr advance_lineptr
    jsr parse_word

    ldy #0
    lda (lineptr),y
    cmp #','
    beq pa_paren_comma
    cmp #')'
    beq pa_paren_close
    jmp cmd_error

pa_paren_comma:
    jsr advance_lineptr
    ldy #0
    lda (lineptr),y
    jsr toupper
    cmp #'X'
    beq pa_paren_x
    jmp cmd_error

pa_paren_x:
    jsr advance_lineptr
    ldy #0
    lda (lineptr),y
    cmp #')'
    beq pa_paren_x_close
    jmp cmd_error

pa_paren_x_close:
    jsr advance_lineptr
    lda T0H
    beq pa_indx
    lda #AM_AIX
    sta asm_mode
    rts

pa_indx:
    lda #AM_INDX
    sta asm_mode
    rts

pa_paren_close:
    jsr advance_lineptr
    ldy #0
    lda (lineptr),y
    cmp #','
    beq pa_paren_close_comma

    lda T0H
    beq pa_zpind
    lda #AM_IND
    sta asm_mode
    rts

pa_zpind:
    lda #AM_ZPIND
    sta asm_mode
    rts

pa_paren_close_comma:
    jsr advance_lineptr
    ldy #0
    lda (lineptr),y
    jsr toupper
    cmp #'Y'
    beq pa_paren_y
    jmp cmd_error

pa_paren_y:
    jsr advance_lineptr
    lda T0H
    beq pa_indy
    jmp cmd_error

pa_indy:
    lda #AM_INDY
    sta asm_mode
    rts

pa_value:
    jsr parse_word

    ldy #0
    lda (lineptr),y
    cmp #','
    beq pa_value_comma

    lda T0H
    beq pa_zp
    lda #AM_ABS
    sta asm_mode
    rts

pa_zp:
    lda #AM_ZP
    sta asm_mode
    rts

pa_value_comma:
    jsr advance_lineptr
    ldy #0
    lda (lineptr),y
    jsr toupper
    cmp #'X'
    beq pa_index_x
    cmp #'Y'
    beq pa_index_y

    lda T0H
    beq pa_zprel
    jmp cmd_error

pa_zprel:
    lda T0L
    sta T1L
    jsr parse_word
    lda #AM_ZPREL
    sta asm_mode
    rts

pa_index_x:
    jsr advance_lineptr
    lda T0H
    beq pa_zpx
    lda #AM_ABSX
    sta asm_mode
    rts

pa_zpx:
    lda #AM_ZPX
    sta asm_mode
    rts

pa_index_y:
    jsr advance_lineptr
    lda T0H
    beq pa_zpy
    lda #AM_ABSY
    sta asm_mode
    rts

pa_zpy:
    lda #AM_ZPY
    sta asm_mode
    rts
		
; ------------------------------------------------------------
; FIND OPCODE
;
; Input:
;   mnemonic in R1/mnem_len
;   asm_mode
;
; Output:
;   C = 1 found
;   asm_opcode = opcode
;   C = 0 not found
;
; Special case:
;   branch mnemonics accept AM_REL when operand parsed as ZP or ABS
; ------------------------------------------------------------
find_opcode:
    ldx #0

fo_loop:
    lda mode_table,x
    cmp asm_mode
    beq fo_check_mnemonic_direct

    cmp #AM_REL
    bne fo_next

    lda asm_mode
    cmp #AM_ZP
    beq fo_check_mnemonic_rel
    cmp #AM_ABS
    beq fo_check_mnemonic_rel
    jmp fo_next

fo_check_mnemonic_direct:
    jsr get_mnemonic_id_x
    jsr get_mnemonic_ptr_id
    jsr compare_mnemonic
    bcs fo_found_direct
    jmp fo_next

fo_check_mnemonic_rel:
    jsr get_mnemonic_id_x
    jsr get_mnemonic_ptr_id
    jsr compare_mnemonic
    bcs fo_found_rel
    jmp fo_next

fo_found_rel:
    lda #AM_REL
    sta asm_mode
    stx asm_opcode
    sec
    rts

fo_found_direct:
    stx asm_opcode
    sec
    rts

fo_next:
    inx
    bne fo_loop
    clc
    rts

; ------------------------------------------------------------
; COMPUTE_REL_OFFSET
;
; Input:
;   A  = instruction length (2 or 3)
;   R0 = instruction address
;   T0 = target address
;
; Output:
;   A  = signed 8-bit relative offset
;
; Error:
;   jumps to cmd_error if target is out of range
; ------------------------------------------------------------
compute_rel_offset:
    sta parm_count

    ; R3 = base = R0 + instruction length
    lda R0L
    clc
    adc parm_count
    sta R3L
    lda R0H
    adc #0
    sta R3H

    ; diff = target - base   (wrapped 16-bit subtraction)
    sec
    lda T0L
    sbc R3L
    sta T1L
    lda T0H
    sbc R3H
    sta T1H

    ; valid if:
    ;   T1 = 00:00..00:7F   (+0 .. +127)
    ;   T1 = FF:80..FF:FF   (-128 .. -1)

    lda T1H
    beq cro_pos
    cmp #$FF
    beq cro_neg
    jmp cmd_error

cro_pos:
    lda T1L
    cmp #$80
    bcc cro_ok
    jmp cmd_error

cro_neg:
    lda T1L
    cmp #$80
    bcs cro_ok
    jmp cmd_error

cro_ok:
    lda T1L
    rts
		
; ------------------------------------------------------------
; EMIT INSTRUCTION
; Uses asm_opcode, asm_mode and operand value(s).
; Updates MEM to next address.
; Writes nothing if relative offset is out of range.
; ------------------------------------------------------------
emit_instruction:
    lda asm_mode
    jsr get_oplen_from_mode
    sta tmp

    ; for relative forms, validate offset before storing opcode
    lda asm_mode
    cmp #AM_REL
    beq ei_prep_rel
    cmp #AM_ZPREL
    beq ei_prep_zprel
    jmp ei_store

ei_prep_rel:
    lda #2
    jsr compute_rel_offset
    sta T1H
    jmp ei_store

ei_prep_zprel:
    lda #3
    jsr compute_rel_offset
    sta T1H
    jmp ei_store

ei_store:
    ldy #0
    lda asm_opcode
    sta (R0L),y

    lda tmp
    cmp #1
    beq ei_finish

    lda asm_mode
    cmp #AM_REL
    beq ei_rel
    cmp #AM_ZPREL
    beq ei_zprel

    ldy #1
    lda T0L
    sta (R0L),y

    lda tmp
    cmp #2
    beq ei_finish

    iny
    lda T0H
    sta (R0L),y
    jmp ei_finish

ei_rel:
    ldy #1
    lda T1H
    sta (R0L),y
    jmp ei_finish

ei_zprel:
    ldy #1
    lda T1L
    sta (R0L),y
    iny
    lda T1H
    sta (R0L),y

ei_finish:
    lda tmp
    jsr add_R0_A
    lda R0L
    sta MEML
    lda R0H
    sta MEMH
    rts
