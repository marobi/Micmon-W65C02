# -------------------------------------------------
# Toolchain
# -------------------------------------------------

AS      := ca65
LD      := ld65
BIN2ROM := bin2rom
DISASM  := python disasm6502.py
CP      := cp
RM      := rm -f

# -------------------------------------------------
# Project configuration
# -------------------------------------------------

TARGET      := micmon
SRC         := $(TARGET).asm
OBJ         := $(TARGET).o
BIN         := $(TARGET).bin
ROM         := $(TARGET).rom
MAP         := $(TARGET).map
LBL         := $(TARGET).lbl
LST         := $(TARGET).LST
TXT			:= $(TARGET).txt
CFG         := neo6502.cfg

BASE_DIR := /cygdrive/c/Users/rien/OneDrive/source/repos
PROJECT_DIR := /NEO6502_MMU_V3/NEO6502_MMU_V3
INSTALL_DIR := $(BASE_DIR)$(PROJECT_DIR)/data/system

# -------------------------------------------------
# Default target
# -------------------------------------------------

.PHONY: all clean distclean install

all: $(ROM) $(LST)

# -------------------------------------------------
# Build rules
# -------------------------------------------------

$(ROM): $(BIN)
	$(BIN2ROM) -B $(shell ./getaddress) -o $@ $<

$(BIN): $(OBJ) $(CFG)
	$(LD) -C $(CFG) -vm -m $(MAP) -Ln $(LBL) -o $@ $<

$(OBJ): $(SRC) micmon.asm readme.asm disasm.asm asm.asm asm_data.asm ../bios/bios.h
	$(AS) --cpu W65C02 -g -l $(LST) -o $@ $<

# -------------------------------------------------
# Absolute listing (generated from ROM)
# -------------------------------------------------

$(LST): $(BIN) $(MAP) $(LBL)
	$(DISASM) $(BIN) $(MAP) $(LBL) > $(TXT)

# -------------------------------------------------
# Install
# -------------------------------------------------

install: $(ROM)
	$(CP) $< $(INSTALL_DIR)

# -------------------------------------------------
# Cleanup
# -------------------------------------------------

clean:
	$(RM) *.o *.map *.lbl *.bin *.lst *.txt

distclean: clean
	$(RM) *.rom
	