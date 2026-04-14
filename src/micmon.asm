; ---------------------------------------------------------------------------
; MICMON – Minimal Interactive Command Monitor for the W65C02
; (c) 2026 Rien Matthijsse
; ---------------------------------------------------------------------------
.include "readme.asm"

	.setcpu "65C02"

.include "bios.inc"

	.segment "ZEROPAGE"
	.org $00C0					; nicer listing

; IRQ hander vector
irq_vecL:   .res 1
irq_vecH:   .res 1

; parser / dispatcher pointers
lineptr:    .res 2
jmpvec:     .res 2

; 16-bit working registers for commands
R0L:        .res 1
R0H:        .res 1
R1L:        .res 1
R1H:        .res 1
R2L:        .res 1
R2H:        .res 1
R3L:        .res 1
R3H:        .res 1

; temporary registers used by parser and utility routines
T0L:        .res 1
T0H:        .res 1
T1L:        .res 1
T1H:        .res 1

; monitor remembers last referenced memory address
MEML:       .res 1
MEMH:       .res 1

; parser state
parm_count: .res 1
value_size: .res 1
tmp:        .res 1

asm_mode:   .res 1
asm_opcode: .res 1
mnem_len:   .res 1

; context
save_sp:	.res 1

	.segment "BSS"
	.org $0200				; nicer listing

; input buffer
linebuf:    .res 64

; saved CPU image
reg_pch:    .res 1
reg_pcl:    .res 1
reg_sr:     .res 1
reg_a:      .res 1
reg_x:      .res 1
reg_y:      .res 1
reg_sp:     .res 1

	.segment "CODE"
	.org $B000				; nicer listing

; ------------------------------------------------------------
; RESET
; Basic CPU setup, monitor state initialization, then enter
; the monitor through BRK so startup uses the normal entry path.
; ------------------------------------------------------------
	.export reset
reset:
    sei						; disable interrupts
    cld
    ldx #$FF
    txs						; init stack

    stz MEML
    stz MEMH
	lda #<context_switch	; set interrupt vector
    sta irq_vecL
	lda #>context_switch
    sta irq_vecH

	jsr $E029				; temp clutch!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	
    lda #<welcome_text		; say hello
    ldx #>welcome_text
    jsr print_str

	brk						; enter monitor
		
; ------------------------------------------------------------
; IRQ / BRK ENTRY
; Shared entry for hardware IRQ and BRK.
;
; BRK enters the monitor.
; IRQ dispatches through irq_vec
; ------------------------------------------------------------
	.export irq_entry
irq_entry:
    pha						; save rest of context
    phx
    phy

    tsx
	stx save_sp				; save current SP
    lda $0104,x             ; stacked SR after PHA/PHX/PHY
    and #$10
    bne brk_entry			; BREAK

irq_dispatch:				; IRQ
    jmp (irq_vecL)

; ------------------------------------------------------------
; expects the full context to be saved on stack
; micmon must be shared between all contexts and loaded last
;
context_switch:				; for now default irq vector
	lda BIOS_SYNC_PORT
	beq context_switch		; wait for prev release, should not happen
							; now 1
	stz BIOS_SYNC_PORT		; arm
							; now 0
wait_ack:					; rp2350 will perform context switch
	lda BIOS_SYNC_PORT
	beq wait_ack			; wait for completion
							; now 1
	lda BIOS_STAT_PORT		; what to do?
	cmp #$01				; when 1
	beq irq_restore			; restore context
	jmp ($FFFC)				; else exec reset
							
irq_restore:				; context switched
	ldx save_sp
	txs						; restore SP
    ply						; restore context
    plx
    pla
    rti						; and continue

	.export nmi_entry
nmi_entry:
    rti						; stub

print_context:
    tsx
	
; ------------------------------------------------------------
; BRK ENTRY
; Save CPU state into monitor RAM and discard interrupt frame.
; BRK pushes PC+2, so saved PC is corrected back to BRK opcode.
; ------------------------------------------------------------
brk_entry:
    pla						; save context
    sta reg_y
    pla
    sta reg_x
    pla
    sta reg_a
    pla
    sta reg_sr
    pla
    sta reg_pcl
    pla
    sta reg_pch

    tsx
    stx reg_sp

    cld
    sec						; correct PC =-2
    lda reg_pcl
    sbc #2
    sta reg_pcl
    lda reg_pch
    sbc #0
    sta reg_pch

; ------------------------------------------------------------
; MONITOR ENTRY
; Every BRK entry shows the saved registers, then drops into
; the command loop.
; ------------------------------------------------------------
monitor_entry:
	cli					; enable interrupts
    jsr show_registers	; show regs and fall through
	jsr print_prompt

; ------------------------------------------------------------
; MAIN MONITOR LOOP
; Read one full line, execute it
; ------------------------------------------------------------
monitor_loop:
    jsr getline					; read line
    lda #<linebuf
    sta lineptr
    lda #>linebuf
    sta lineptr+1

execute_line:
    jsr skip_spaces
    ldy #0
    lda (lineptr),y			; get cmd
    beq exec_done
    jsr toupper
    sta (lineptr),y			; save uppercase
    jsr dispatch_command
	bcs exec_nopr
exec_done:
	jsr print_prompt
		
exec_nopr:
    jmp monitor_loop
 
; ------------------------------------------------------------
; COMMAND DISPATCH
; ------------------------------------------------------------
dispatch_command:
    ldy #0
    lda (lineptr),y
    sta tmp

    ldx #0
dispatch_loop:
    lda cmd_chars,x
    beq dispatch_error
    cmp tmp
    beq dispatch_found
    inx
    jmp dispatch_loop

dispatch_found:
    txa
    asl
    tax
    lda cmd_addrs,x
    sta jmpvec
    inx
    lda cmd_addrs,x
    sta jmpvec+1
    jmp (jmpvec)

dispatch_error:
    jmp cmd_error

; ------------------------------------------------------------
; RESET COMMAND
; ------------------------------------------------------------
cmd_reset:
		jmp reset
		
; ------------------------------------------------------------
; MEMORY DUMP COMMAND
; Syntax:
;   M
;   M start
;   M start end
;
; Default start is MEM.
; Default length is 12 lines * 8 bytes = 96 bytes.
; MEM is updated to the next address after the dump.
; ------------------------------------------------------------
cmd_mem:
	jsr advance_lineptr
		
    jsr next_token
    bcc mem_default

    jsr parse_word
    jsr copy_T0_R0

    jsr next_token
    bcc mem_one_param

    jsr parse_word
    jsr copy_T0_R1
    jmp mem_prepare

mem_default:
    jsr copy_MEM_R0
mem_one_param:
    jsr copy_R0_R1
    lda #95
    jsr add_R1_A

mem_prepare:
    jsr next_token
    bcc mem_prepare_ok
    jmp cmd_error

mem_prepare_ok:
    jsr copy_R0_R2

mem_loop:
    jsr check_abort
    bcs mem_abort

    jsr dump_line

    lda #8
    jsr add_R2_A
    bcs mem_ok

    jsr cmp_R2_R1
    bcc mem_loop
    beq mem_loop
		
mem_ok:
    jsr copy_R2_MEM
    clc
	rts

mem_abort:
    jmp cmd_error
		
; ------------------------------------------------------------
; MEMORY EDIT COMMAND
; Syntax:
;   > addr byte...
; Writes 1..8 bytes.
; Updates MEM to the next address after the last write.
; ------------------------------------------------------------
cmd_memedit:
	jsr advance_lineptr
    jsr parse_word
    jsr copy_T0_R0				; init ptr

    stz parm_count				; first of 8

write_loop:
    lda parm_count
    cmp #8
    bcs write_done				; >= 7

    jsr next_token
    bcc write_done				; no more

    jsr parse_byte

    ldy #0
    lda T0L
    sta (R0L),y						; store it

    jsr inc_R0						; next location
    inc parm_count				; next param
    jmp write_loop				; loop

write_done:
    lda parm_count
    beq write_error				; no locations given

    lda R0L								; advance mem ptr
    sta MEML
    lda R0H
    sta MEMH
    clc
	rts

write_error:
    jmp cmd_error
		

; ------------------------------------------------------------
; REGISTER DISPLAY COMMAND
; Explicit register display on user request.
; ------------------------------------------------------------
cmd_regs:
show_registers:
    lda #<reg_header
    ldx #>reg_header
    jsr print_str

print_reg_line:
    lda #';'							; in sync with command table
    jsr putchar
    jsr print_space

    lda reg_pch
    ldx reg_pcl
    jsr print_hex16
    jsr print_space

    lda reg_a
    jsr print_hex8
    jsr print_space

    lda reg_x
    jsr print_hex8
    jsr print_space

    lda reg_y
    jsr print_hex8
    jsr print_space

    lda reg_sp
    jsr print_hex8
    jsr print_space

    lda #'%'
		jsr putchar
    lda reg_sr
    jsr print_status_bits
    jsr newline
	clc
	rts
		
; ------------------------------------------------------------
; REGISTER EDIT COMMAND
; Editable line format:
;   ; <PC> [A [X [Y [SP [SR]]]]]
;
; At least PC must be supplied.
; Missing trailing operands leave saved registers unchanged.
; ------------------------------------------------------------
cmd_regedit:
	jsr advance_lineptr

    jsr next_token
    bcc regedit_error

    jsr parse_word
    lda T0L
    sta reg_pcl
    lda T0H
    sta reg_pch

    jsr next_token
    bcc regedit_done

    jsr parse_byte
    lda T0L
    sta reg_a

    jsr next_token
    bcc regedit_done

    jsr parse_byte
    lda T0L
    sta reg_x

    jsr next_token
    bcc regedit_done

    jsr parse_byte
    lda T0L
    sta reg_y

    jsr next_token
    bcc regedit_done

    jsr parse_byte
    lda T0L
    sta reg_sp

    jsr next_token
    bcc regedit_done

    jsr parse_byte
    lda T0L
    sta reg_sr

    jsr next_token

regedit_done:
	jsr show_registers
	clc
    rts

regedit_error:
    jmp cmd_error
	
; ------------------------------------------------------------
; GO COMMAND
; Syntax:
;   G
;   G <PC>
; Restores the saved CPU image and resumes execution with RTI.
; ------------------------------------------------------------
cmd_go:
	jsr advance_lineptr
    jsr next_token
    bcc go_now

    jsr parse_word
    lda T0L
    sta reg_pcl
    lda T0H
    sta reg_pch

    jsr next_token
    bcc go_now
    jmp cmd_error

go_now:
    ldx reg_sp
    txs
    lda reg_pch
    pha
    lda reg_pcl
    pha
    lda reg_sr
    pha
    lda reg_a
    ldx reg_x
    ldy reg_y
    rti

; ------------------------------------------------------------
; HELP COMMAND
; ------------------------------------------------------------
cmd_help:
    lda #<help_text
    ldx #>help_text
    jsr print_str
	clc
	rts
		
; ------------------------------------------------------------
; ERROR HANDLER
; ------------------------------------------------------------
cmd_error:
    jsr print_error
	sec
	rts
		
; ------------------------------------------------------------
; MEMORY DUMP FORMATTERS
; ------------------------------------------------------------
; show 8 memory locs @R2
.proc dump_line
    lda #'>'						; sync with command table 
    jsr putchar
    jsr print_space

    lda R2L
    sta T0L
    lda R2H
    sta T0H
    jsr print_address_T0

    ldy #0
dump_hex_loop:
    lda (R2L),y
    jsr print_hex8
    jsr print_space
    iny
    cpy #8
    bne dump_hex_loop

    jsr print_space

    ldy #0
dump_ascii_loop:
    lda (R2L),y
    jsr print_ascii
    iny
    cpy #8
    bne dump_ascii_loop
    jmp newline
.endproc

; ------------------------------------------------------------
; OUTPUT HELPERS
; ------------------------------------------------------------

; ------------------------------------------------------------
; STRING OUTPUT
; A = low byte, X = high byte of zero-terminated string.
; Uses T0 as the temporary string pointer.
; ------------------------------------------------------------
.proc print_str
    phy
    sta T0L
    stx T0H
    ldy #0

print_str_loop:
    lda (T0L),y
    beq print_str_done
    jsr putchar
    iny
    bne print_str_loop
    inc T0H
    jmp print_str_loop

print_str_done:
    ply
	rts
.endproc

; ------------------------------------------------------------
; PRINT_STATUS_BITS
; Print processor status as:
;   NV-BDIZC
; using '1' for set bits and '0' for clear bits.
;
; Input
;   A = status byte
;
; Clobbers
;   A, X
; ------------------------------------------------------------
.proc print_status_bits
    sta tmp

    asl tmp              ; N -> C
    jsr print_bit_c

    asl tmp              ; V -> C
    jsr print_bit_c

    lda #'-'						 ; mmmhhhh
    jsr putchar

    asl tmp              ; skip bit 5

    ldx #5               ; B D I Z C
ps_loop:
    asl tmp              ; next bit -> C
    jsr print_bit_c
    dex
    bne ps_loop
    rts
.endproc

; ------------------------------------------------------------
; PRINT_BIT_C
; Print '1' if Carry set, else '0'.
; ------------------------------------------------------------
.proc print_bit_c
    bcc ps_zero
    lda #'1'
    jmp putchar
ps_zero:
    lda #'0'
    jmp putchar
.endproc

; ------------------------------------------------------------
; PRINT ADDRESS IN T0 + one trailing space
; ------------------------------------------------------------
.proc print_address_T0
    lda T0H
    ldx T0L
    jsr print_hex16
    jmp print_space
.endproc
		
; ------------------------------------------------------------
; TOKENIZER
; Carry set   = token exists
; Carry clear = end of line
; ------------------------------------------------------------
.proc next_token
    jsr skip_spaces
    ldy #0
    lda (lineptr),y
    beq token_eol
    sec
    rts

token_eol:
    clc
    rts
.endproc

; ------------------------------------------------------------
; PARAMETER PARSER
; Default base is hex.
; Supported prefixes:
;   $ hex
;   + decimal
;   % binary   (byte only)
;   ' ASCII    (byte only)
; Result is returned in T0, size in value_size.
; ------------------------------------------------------------
.proc parse_param
    jsr skip_spaces
    ldy #0
    lda (lineptr),y
    beq param_error

    cmp #'$'
    beq parse_hex_pref
    cmp #'+'
    beq parse_dec
    cmp #'%'
    beq parse_bin
    cmp #$27
    beq parse_ascii

    jmp parse_hex

parse_hex_pref:
    jsr advance_lineptr
    jmp parse_hex

parse_dec:
    jsr advance_lineptr
    jmp parse_decimal

parse_bin:
    jsr advance_lineptr
    jmp parse_binary

parse_ascii:
    jsr advance_lineptr
    jmp parse_ascii_char

param_error:
    jmp cmd_error
.endproc

.proc parse_byte
    jsr parse_param
    lda value_size
    cmp #1
    beq parse_byte_ok
    jmp cmd_error
parse_byte_ok:
    rts
.endproc

.proc parse_word
    jmp parse_param
.endproc

; ------------------------------------------------------------
; ASCII PARSER
; Syntax: 'A
; ------------------------------------------------------------
.proc parse_ascii_char
    ldy #0
    lda (lineptr),y
    beq ascii_error
    sta T0L
    stz T0H
    lda #1
    sta value_size
    jmp advance_lineptr

ascii_error:
    jmp cmd_error
.endproc

; ------------------------------------------------------------
; BINARY PARSER
; Syntax: %10101010
; Binary values are byte sized only.
; ------------------------------------------------------------
.proc parse_binary
    stz T0L
    stz T0H
    stz tmp

bin_loop:
    ldy #0
    lda (lineptr),y
    cmp #'0'
    beq bin_zero
    cmp #'1'
    beq bin_one
    cmp #'-'				; special case for S-register
    beq bin_one
    jmp bin_done

bin_zero:
    lda tmp
    cmp #8
    bcs bin_error
    asl T0L
    jsr advance_lineptr
    inc tmp
    jmp bin_loop

bin_one:
    lda tmp
    cmp #8
    bcs bin_error
    asl T0L
    inc T0L
    jsr advance_lineptr
    inc tmp
    jmp bin_loop

bin_done:
    lda tmp
    beq bin_error
    lda #1
    sta value_size
    rts

bin_error:
    jmp cmd_error
.endproc

; ------------------------------------------------------------
; HEX PARSER
; 1-2 digits => byte, 3-4 digits => word.
; ------------------------------------------------------------
.proc parse_hex
    stz T0L
    stz T0H
    stz tmp

hex_loop:
    ldy #0
    lda (lineptr),y
    jsr hex_digit
    bcs hex_done

    asl T0L
    rol T0H
    asl T0L
    rol T0H
    asl T0L
    rol T0H
    asl T0L
    rol T0H

    ora T0L
    sta T0L

    jsr advance_lineptr
    inc tmp
    jmp hex_loop

hex_done:
    lda tmp
    beq hex_error
    cmp #3
    bcc hex_byte
    cmp #5
    bcc hex_word
    jmp cmd_error

hex_byte:
    lda #1
    sta value_size
    rts

hex_word:
    lda #2
    sta value_size
    rts

hex_error:
    jmp cmd_error
.endproc

; ------------------------------------------------------------
; DECIMAL PARSER
; Syntax: +1234
; Uses repeated 16-bit add:
;   T0 = T0 * 10 + digit
; ------------------------------------------------------------
.proc parse_decimal
    stz T0L
    stz T0H
    stz value_size

dec_loop:
    ldy #0
    lda (lineptr),y
    cmp #'0'
    bcc dec_done
    cmp #'9'+1
    bcs dec_done

    sec
    sbc #'0'
    sta tmp

    jsr copy_T0_T1

    stz T0L
    stz T0H
    ldx #10

dec_mul_loop:
    jsr add_T1_T0
    dex
    bne dec_mul_loop

    clc
    lda T0L
    adc tmp
    sta T0L
    bcc dec_next
    inc T0H

dec_next:
    jsr advance_lineptr
    inc value_size
    jmp dec_loop

dec_done:
    lda value_size
    beq dec_error
    lda T0H
    beq dec_byte
    lda #2
    sta value_size
    rts

dec_byte:
    lda #1
    sta value_size
    rts

dec_error:
    jmp cmd_error
.endproc

; ------------------------------------------------------------
; HEX_DIGIT
; Convert ASCII hex digit to value 0..15.
;
; Input
;   A = ASCII character
;
; Output
;   A = digit value
;   C = 0 valid digit
;   C = 1 invalid digit
; ------------------------------------------------------------
hex_digit:
    cmp #'0'
    bcc hex_bad
    cmp #'9'+1
    bcc hex_num

    cmp #'A'
    bcc hex_lower
    cmp #'F'+1
    bcc hex_upper

hex_lower:
    cmp #'a'
    bcc hex_bad
    cmp #'f'+1
    bcs hex_bad
    sec
    sbc #'a'-10
    clc
    rts

hex_upper:
    sec
    sbc #'A'-10
    clc
    rts

hex_num:
    sec
    sbc #'0'
    clc
    rts

hex_bad:
    sec
    rts

; ------------------------------------------------------------
; TEXT POINTER HELPERS
; ------------------------------------------------------------
.proc advance_lineptr
    inc lineptr
    bne ptr_done
    inc lineptr+1
ptr_done:
    rts
.endproc

.proc skip_spaces
    ldy #0
    lda (lineptr),y
    cmp #' '
    bne skip_done
    jsr advance_lineptr
    jmp skip_spaces
		
skip_done:
    rts
.endproc

.proc toupper
    cmp #'a'
    bcc upper_done
    cmp #'z'+1
    bcs upper_done
    and #%11011111
upper_done:
    rts
.endproc

; ------------------------------------------------------------
; 16-bit register / monitor pointer primitives
; ------------------------------------------------------------
.proc copy_T0_T1
    lda T0L
    sta T1L
    lda T0H
    sta T1H
    rts
.endproc
		
.proc copy_T0_R0
    lda T0L
    sta R0L
    lda T0H
    sta R0H
    rts
.endproc

.proc copy_T0_R1
    lda T0L
    sta R1L
    lda T0H
    sta R1H
    rts
.endproc

.proc copy_R0_R1
    lda R0L
    sta R1L
    lda R0H
    sta R1H
    rts
.endproc

.proc copy_R0_R2
    lda R0L
    sta R2L
    lda R0H
    sta R2H
    rts
.endproc

.proc copy_MEM_R0
    lda MEML
    sta R0L
    lda MEMH
    sta R0H
    rts
.endproc

.proc copy_R2_MEM
    lda R2L
    sta MEML
    lda R2H
    sta MEMH
    rts
.endproc

.proc inc_R0
    inc R0L
    bne inc_r0_done
    inc R0H
inc_r0_done:
    rts
.endproc

.proc inc_R2
    inc R2L
    bne inc_r2_done
    inc R2H
inc_r2_done:
    rts
.endproc

.proc add_R0_A
    clc
    adc R0L
    sta R0L
    bcc add_r0_no_wrap
    inc R0H
    beq add_r0_wrap
add_r0_no_wrap:
    clc
    rts
add_r0_wrap:
    sec
    rts
.endproc

.proc add_R1_A
    clc
    adc R1L
    sta R1L
    bcc add_r1_no_wrap
    inc R1H
    beq add_r1_wrap
add_r1_no_wrap:
    clc
    rts
add_r1_wrap:
    sec
    rts
.endproc

; ------------------------------------------------------------
; ADD_R2_A
; Add unsigned byte in A to 16-bit register R2.
;
; Returns:
;   C = 1 only if 16-bit wrap occurred ($FFFF -> $0000)
;   C = 0 otherwise
; ------------------------------------------------------------
.proc add_R2_A
    clc
    adc R2L
    sta R2L
    bcc add_r2_no_wrap

    inc R2H
    beq add_r2_wrap

add_r2_no_wrap:
    clc
    rts

add_r2_wrap:
    sec
    rts
.endproc

.proc add_T1_T0
    clc
    lda T0L
    adc T1L
    sta T0L
    lda T0H
    adc T1H
    sta T0H
    rts
.endproc
		
.proc cmp_R2_R1
    lda R2H
    cmp R1H
    bne cmp_r2_r1_done
    lda R2L
    cmp R1L
cmp_r2_r1_done:
    rts
.endproc
		
;------------------------------------------------
.proc print_hex8
    pha
    lsr
    lsr
    lsr
    lsr
    jsr print_hex_digit
    pla
    and #$0F

print_hex_digit:
    cmp #10
    bcc print_hex_num
    clc
    adc #'A'-10
    jmp putchar
.endproc

.proc print_hex_num
    clc
    adc #'0'
    jmp putchar
.endproc

; ------------------------------------------------------------
; PRINT_HEX16
; Print 16-bit value in hexadecimal.
;
; Input
;   A = high byte
;   X = low byte
; ------------------------------------------------------------
.proc print_hex16
    phx
    jsr print_hex8
    plx
    txa
    jmp print_hex8
.endproc
		
.proc print_ascii
    cmp #$20
    bcc ascii_dot
    cmp #$7F
    bcs ascii_dot
    jmp putchar
.endproc

.proc ascii_dot
    lda #'.'
    jmp putchar
.endproc

.proc print_space
    lda #' '
    jmp putchar
.endproc

.proc newline
    lda #$0D
    jmp putchar
.endproc

.proc print_prompt
		lda #<prompt_text
    ldx #>prompt_text
    jmp print_str
.endproc 

; ------------------------------------------------------------
; GETLINE
; Read a line from input into linebuf.
;
; Assumptions
; - host terminal performs line editing
; - CR (0x0D) terminates the line
; - line is zero terminated
; - max length = 127 characters
; ------------------------------------------------------------
.proc getline
    ldx #0

getline_loop:
    jsr getchar
    cmp #$0D
    beq getline_done
    cmp #$0A
    beq getline_done

    cpx #59
    bcs getline_loop

    sta linebuf,x
    inx
    jmp getline_loop

getline_done:
    lda #0
    sta linebuf,x
    rts
.endproc
		
.proc print_error
	lda #'?'
	jsr putchar
	jmp newline
.endproc

; ------------------------------------------------------------
; I/O
; ------------------------------------------------------------
.proc getchar
	jsr BIOS_GETCHAR
	beq getchar
	rts
.endproc

.proc putchar
    jmp BIOS_PUTCHAR
.endproc

; ------------------------------------------------------------
; CHECK_ABORT
; Test if the user pressed ^C.
;
; Returns
;   C = 1  abort requested
;   C = 0  continue
;
; Wrapper around BIOS_STPKEY so the monitor depends only on
; this primitive instead of calling the BIOS everywhere.
; ------------------------------------------------------------
check_abort:
    clc
    rts
				
; command implementations
.include "disasm.asm"

.include "asm.asm"

.include "asm_data.asm"

; ------------------------------------------------------------
;
; ------------------------------------------------------------
cmd_chars:
    .byte 'H', 'M', '>', 'R', ';', 'G', 'D', 'A', 'X', 0

cmd_addrs:
	.word cmd_help
    .word cmd_mem
    .word cmd_memedit
    .word cmd_regs
    .word cmd_regedit
    .word cmd_go
	.word cmd_disasm
	.word cmd_asm
	.word cmd_reset

welcome_text:
	.byte 12, "Micmon v0.9f", $0D, $0D, 0
		
reg_header:
    .byte "   PC  A  X  Y  S   NV-BDIZC", $0D, 0

prompt_text:
	.byte "OK", $0D, 0
		
help_text:
    .byte "M [s [e]]",$0D
    .byte "> [s] bt[s]",$0D
    .byte "R",$0D
    .byte "; PC A X Y S P",$0D
    .byte "G [s]",$0D
    .byte "D [s]",$0D
    .byte "A [s] stmt",$0D
	.byte "X", $0D
    .byte "H",$0D,0
		
; ------------------------------------------------------------
;
; ------------------------------------------------------------
	.segment "VECTORS"

;    .word nmi_entry
;    .word reset
;    .word irq_entry
