# MICMON -- Minimal Interactive Command Monitor for the W65C02

(c) 2026 Rien Matthijsse

------------------------------------------------------------------------

## Overview

Micmon is a compact machine-level monitor for the W65C02, designed to
fit within a 4 KB ROM. It provides essential debugging, inspection, and
control facilities while remaining small, deterministic, and fully
self-hosting.

The monitor follows a strict **round-trip philosophy**: all output is
valid input. Any command output (e.g. memory dumps) can be edited and
fed back into the monitor for execution. This enables interactive
workflows using external terminals or VDUs with line editing
capabilities.

------------------------------------------------------------------------

## Design Goals

-   Minimal footprint (fits in 4 KB ROM)
-   Deterministic behaviour (no hidden state, no dynamic allocation)
-   Table-driven architecture (command dispatch, disassembler,
    assembler)
-   Round-trip capable output (monitor output is executable input)
-   Tight integration with external VDU/GDU systems

------------------------------------------------------------------------

## Functional Scope

-   Memory inspection and modification
-   CPU register inspection and editing
-   Program execution control (GO)
-   Disassembler (W65C02 complete)
-   Inline assembler (single-line, immediate emission)
-   Command-driven interface with single-character dispatch

------------------------------------------------------------------------

## Command Summary

H Help / command overview\
M addr Peek memory\
\> addr Poke memory (byte stream)\
R Show CPU registers\
; Modify CPU registers\
G \[addr\] Execute code at address\
D \[addr\] Disassemble\
A \[addr\] Assemble single instruction at address

------------------------------------------------------------------------

## Notes

-   If no address is provided, the current address pointer is used
-   Commands are line-oriented and CR-terminated
-   Where possible: output format is compatible with monitor input (round-trip)

------------------------------------------------------------------------

## Execution Model

### RESET

-   Initializes CPU state and monitor environment
-   Enters monitor via BRK vector

### BRK Handler

-   Saves full CPU context (A, X, Y, P, SP, PC)
-   Transfers control to command interpreter

### Command Loop

-   Line-oriented input\
-   Single-character command dispatch via table
-   Commands operate directly on memory and CPU image

------------------------------------------------------------------------

## Interaction Model

Micmon assumes the host terminal or VDU performs line editing.
Input is processed per line (CR-terminated).

Example:

M 0200 020F\
\> 0200 A9 01 8D 00 02 ...

Can be edited into:

\> 0200 A9 AA 8D 00 02

and executed directly by the monitor.

------------------------------------------------------------------------

## Parameter Formats

All numeric parameters support multiple input formats.
The format is determined strictly by prefix; otherwise hexadecimal is
assumed.

### Supported Formats

-   Hex (default): 0200, \$0200
-   Decimal: +123
-   Binary: %10101010
-   ASCII: 'A → \$41

### Rules

-   Hex is assumed if no prefix is present
-   Prefixes:
    -   \$ = hexadecimal (optional)
    -   \% = binary
    -   \+ = decimal
    -   \' = ASCII single byte
-   Parsed result:
    -   T0 = value (byte or word)
    -   value_size \>= 1 indicates success
-   Commands operate on parsed values only

### Examples

M \$C000\
M %1100000000000000\
M +49152

\> 0200 \'A \$42 %01000011

A 0300 LDA \#'A\
A 0302 LDA #\$41\

------------------------------------------------------------------------

## Architecture Notes

-   All decoding is table-driven
-   Opcode metadata shared between assembler and disassembler
-   Zero-page used from \$00C0--\$00DF
-   Strict separation between parsing, decoding, and execution

------------------------------------------------------------------------

## Extensibility

-   Add commands via cmd_chars / cmd_addrs
-   Fully table-driven dispatch (no switch-case)
-   Reusable parsing helpers
-   Shared assembler/disassembler tables
-   Extend via table updates only

------------------------------------------------------------------------

## Limitations

-   No multi-line assembly or labels
-   No expression evaluator
-   Branch range limited to signed 8-bit

------------------------------------------------------------------------

## Target

WDC W65C02

------------------------------------------------------------------------
