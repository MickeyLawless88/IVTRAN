
 # IV-TRAN

**An interactive ANSI FORTRAN IV interpreter in strict C89**

IV-TRAN is a single-file, tree-free (direct text-walking) FORTRAN interpreter that behaves like a period timesharing FORTRAN system: a BASIC-style line-numbered REPL, immediate-mode execution, a batch mode for source files, and optional compiler-style source listings, cross-reference tables and a pseudo-object execution trace.

It targets two hosts from one source file:

- **16-bit MS-DOS** under Turbo C / Borland C (large memory model)
- **Any modern C89 host** (gcc, clang, MSVC)

INTEGER arithmetic is emulated at 16 bits on every host, so programs behave identically on the original DOS target and on a modern machine.

---

## Contents

1. [Building](#building)
2. [Running](#running)
3. [Source form](#source-form)
4. [Language reference](#language-reference)
5. [Input/output and FORMAT](#inputoutput-and-format)
6. [Interactive mode](#interactive-mode)
7. [Listings, cross-reference and trace](#listings-cross-reference-and-trace)
8. [Error messages](#error-messages)
9. [Capacity limits](#capacity-limits)
10. [Deviations from standard FORTRAN](#deviations-from-standard-fortran)
11. [Known issues](#known-issues)
12. [Internals](#internals)

---

## Building

### Modern hosts

```sh
cc -std=c89 -O2 -o ivtran ivtran.c -lm
```

No dependencies beyond the C standard library and libm.

### Turbo C / Borland C (MS-DOS)

```
tcc -ml ivtran.c
```

The **large model (`-ml`) is required.** The largest tables (`prog[]`, `fmts[]`, `asgnCache[]`, `outbuf[]`, `scratchbuf[]`) are declared `far` through the `FARBIG` macro to keep them out of the 64 KB DGROUP, and `prog[].text` is passed to the parser as a plain `char *`. In small or medium model that pointer would be near and silently truncated. `FARBIG` expands to nothing on non-Borland compilers.

---

## Running

```
ivtran [-l | -list | -listing] [-t | -trace] [file]
```

| Option | Effect |
|---|---|
| `file` | Batch mode: load the file, run it once, exit. |
| `-l`, `-list`, `-listing` | Print a compile-style source listing before execution and a symbol/label cross-reference afterwards. |
| `-t`, `-trace` | Print a pseudo-object trace of every executed statement. |
| *(no file)* | Start the interactive REPL. |

The sign-on banner is always printed and reports workspace size, computed from the sizes of the static tables:

```
IV-TRAN REV. 5.21
INTERACTIVE ANSI FORTRAN IV COMPILER/INTERPRETER
COPYRIGHT 1966,1977,1981 (C) RETROCOMPUTING SYSTEMS GROUP
nnnnn BYTES WORKSPACE

READY
```

After each run IV-TRAN reports elapsed CPU time (via `clock()`):

```
EXECUTION TERMINATED.  CPU TIME: 0.05 SEC
```

or, if a runtime error occurred, `EXECUTION TERMINATED ABNORMALLY.`

---

## Source form

IV-TRAN reads **free-format** lines, not fixed columns 1–5 / 6 / 7–72.

| Construct | Rule |
|---|---|
| Label | Leading digits on a line (after optional blanks) are the statement label. |
| Comment | `C` or `c` in **column 1**, or `*` as the first non-blank character. An indented `C` is not a comment, so `CHARACTER` statements can be indented normally. |
| Continuation | A line whose first non-blank character is `+`, `>`, `$` or `&` is appended (with one blank) to the previous line. |
| Blank lines | Ignored. |
| Indentation | Preserved and echoed in listings. |
| Line length | 239 characters, including joined continuations. |
| Case | Keywords, names and `.OP.` operators are case-insensitive; names are folded to uppercase. Uppercase is conventional. |
| Name length | Identifiers are significant to **7 characters**; longer names are silently truncated. |

**Blanks are significant.** Unlike standard FORTRAN, keywords must be followed by a non-alphanumeric character. `DO 10 I = 1, 5` works; `DO10I=1,5` is parsed as an assignment to a variable named `DO10I`. `GO TO` and `GOTO` are both accepted.

### Example

```fortran
      PROGRAM DEMO
C     TABLE OF SQUARES AND ROOTS
      INTEGER N
      REAL R
      WRITE (6,100)
  100 FORMAT (1X, 'N', 9X, 'N**2', 6X, 'SQRT(N)')
      DO 20 N = 1, 5
         R = SQRT(FLOAT(N))
         WRITE (6,110) N, N**2, R
  110    FORMAT (1X, I2, I10, F13.4)
   20 CONTINUE
      STOP
      END
```

---

## Language reference

### Data types

| Type | Storage | Notes |
|---|---|---|
| `INTEGER` | C `long` | `+ - *` and integer `**` wrap to **16-bit two's complement**. Division, constants, storage and intrinsics do not wrap. |
| `REAL` | C `float` | Single precision. |
| `CHARACTER*n` | fixed-length, blank-padded | Scalars and arrays. Assignment truncates or blank-pads to `n`. |
| `LOGICAL` | stored as INTEGER 0/1 | `.TRUE.` = 1, `.FALSE.` = 0. |

Implicit typing follows FORTRAN convention: names beginning `I`–`N` are INTEGER, all others REAL. Explicit declarations override it.

### Declarations

```fortran
      INTEGER I, J, K(10)
      REAL X, Y(3,4)
      LOGICAL DONE
      CHARACTER*20 NAME, LINES(5)*80
      CHARACTER*(LEN) BUF
      DIMENSION A(100), B(0:9, -5:5)
      PARAMETER (LEN = 40, PI = 3.14159)
      DATA X, Y /1.0, 2.0/  STAR/'*'/  TOP/33*'_'/
```

- **Arrays:** up to 3 dimensions, column-major storage, explicit `lower:upper` bounds allowed in any declaration.
- **`CHARACTER`:** length may be given globally (`CHARACTER*20`), per name (`NAME*8`), or as a parenthesised expression such as `CHARACTER*(LEN)`. `*len` and `(dims)` may appear in either order after a name.
- **`PARAMETER`:** sets each name once. Names are not write-protected.
- **`DATA`:** name and value groups may be separated by commas or blanks. An array named in `DATA` is filled by cycling round-robin through the value list. A repeat prefix `N*value` is accepted but not expanded: the single value is cycled, which is correct whenever the count fills the array.
- **Declarations are executable.** They run in program order, so place them before any use.

### Constants

| Form | Example | Notes |
|---|---|---|
| Integer | `42` | |
| Real | `3.5`, `.5`, `1.E-3`, `2E6` | |
| String | `'IT''S'` | `''` is an embedded apostrophe. |
| Hollerith | `1H*`, `4HABCD` | In **expressions and DATA**, only the **first character** is kept, as its character code. In FORMAT statements the full text is used. |
| Logical | `.TRUE.`, `.FALSE.` | |

Storing a quoted string into an INTEGER or REAL variable packs up to its first four bytes into the variable's bit pattern, like classic Hollerith word packing. An `A` edit descriptor unpacks them again.

### Operators

In order from highest to lowest precedence:

| Operators | Notes |
|---|---|
| `**` | Right-associative. INTEGER `**` non-negative INTEGER stays INTEGER (16-bit wrap); anything else is REAL via `pow()`. |
| `-` `+` | |
| `*` `/` | INTEGER division truncates; INTEGER divide-by-zero is a runtime error. |
| `+` `-` | Mixed INTEGER/REAL operations promote to REAL. |
| `//` | Concatenation. Numeric operands are rendered as integer text. |
| `.LT. .LE. .EQ. .NE. .GT. .GE.` | Yield 1 or 0. Strings compare blank-padded to equal length. |
| `.NOT.` | |
| `.AND.` | |
| `.OR.` | |

Parenthesised sub-expressions may contain relational and logical operators.

### Intrinsic functions

| Function | Result |
|---|---|
| `SIN COS TAN ATAN EXP ALOG ALOG10 SQRT ABS` | REAL |
| `IABS IFIX INT NINT` | INTEGER |
| `FLOAT REAL` | REAL |
| `MOD(i,j)` | INTEGER. `MOD(i,0)` is treated as `MOD(i,1)`. |
| `AMOD(a,b)` | REAL (`fmod`) |
| `SIGN(a,b)` | REAL (always, even for INTEGER arguments) |
| `MAX0 MIN0` | INTEGER, any number of arguments |
| `MAX MIN MAX1 MIN1 AMAX0 AMAX1 AMIN0 AMIN1` | REAL, any number of arguments (see [Deviations](#deviations-from-standard-fortran)) |

### Statement functions

```fortran
      F(X, Y) = X**2 + Y**2
      Z = F(3.0, 4.0)
```

- Up to 3 dummy arguments.
- Dummy names are ordinary global variables. Their values are saved before the call and restored after it.
- A line is treated as a statement-function definition only if the name is not already a known variable and the parentheses hold bare names followed by `=`.

### Subprograms

```fortran
      CALL SWAP(A, B)
      ...
      END

      SUBROUTINE SWAP(X, Y)
      T = X
      X = Y
      Y = T
      RETURN
      END

      INTEGER FUNCTION ISQ(N)
      ISQ = N * N
      END
```

- `SUBROUTINE`, `FUNCTION`, `REAL FUNCTION` and `INTEGER FUNCTION` are recognised by a pre-scan. They may appear before or after the main program. Normal execution skips over their bodies.
- **Argument passing:** a bare variable or whole-array name is passed **by reference**. Any other argument (literal, expression, subscripted element) is evaluated once into a scratch copy, and writes to it are not propagated back.
- A function returns the value last assigned to the variable with the function's own name.
- A function reference requires parentheses, even with no arguments: `F()`.
- `END` inside a subprogram acts as an implicit `RETURN`.
- **No local scope.** Every non-argument variable in a subprogram is global and shared with the main program and all other subprograms. Recursion is therefore not meaningful.

### Control flow

| Statement | Notes |
|---|---|
| `GOTO n` / `GO TO n` | |
| `GOTO (n1,n2,...,nk), expr` | Computed GOTO. An out-of-range selector falls through. |
| `IF (expr) n1,n2,n3` | Arithmetic IF: branches on negative, zero or positive. |
| `IF (expr) statement` | Logical IF. The statement may be any executable statement. |
| `IF (expr) THEN` … `ELSE IF (expr) THEN` … `ELSE` … `END IF` | Block IF, nestable. `ENDIF` and `END IF` are both accepted. |
| `DO n var = e1, e2 [, e3]` | INTEGER or REAL index; negative steps allowed. Several DOs may share one terminal label. |
| `CONTINUE` | |
| `STOP`, `END` | Halt the main program. |
| `PROGRAM name` | Accepted; the name appears in listings. |

**DO loops are one-trip** (FORTRAN IV semantics): the body always executes at least once, and the limit is tested only at the terminal statement. REAL DO indices are compared with a 1E-4 tolerance.

---

## Input/output and FORMAT

### Output statements

```fortran
      PRINT 100, A, B
      PRINT *, A, B
      PRINT '(1X, I5, F8.2)', N, X
      WRITE (6,100) A, B
      WRITE (6,*) A, B
      WRITE (*,'(1X,A)') 'HELLO'
```

- The unit number is parsed but ignored. All output goes to stdout.
- Output list items may be expressions, whole arrays (every element, in storage order), or implied-DO lists, nested to any depth: `((A(I,J), J=1,N), I=1,M)`.
- FORMAT statements may appear anywhere and are located by label at run time.

### List-directed output

Each item is written with a leading blank: strings as-is, REAL as `%14.6f`, INTEGER as `%10ld`. One record per statement.

### Edit descriptors

| Descriptor | Meaning | Default when width omitted |
|---|---|---|
| `Iw` | Integer | w = 6 |
| `Fw.d` | Fixed-point real | w = 10, d = 2 |
| `Ew.d` | Exponential real (C `%e` style: `1.2345e+02`) | w = 12, d = 4 |
| `Aw` | Character. INTEGER/REAL values are unpacked from their packed bytes. | w = value length |
| `nX` | n blanks | |
| `nHtext` | Hollerith literal | |
| `'text'` | Quoted literal | |
| `Tn` | Tab to column n (forward only) | |
| `/` | End record | |
| `n(...)` | Repeated group, nestable | |

- Repeat counts apply to `I`, `F`, `E`, `A` and groups.
- **Format reversion** restarts from the beginning of the format when the list has more items than descriptors.
- Output stops at the first data descriptor with no remaining list item.
- Fields are right-justified in width `w`. A value wider than `w` is printed in full; there is no `***` overflow fill.
- Unrecognised descriptor letters (`L`, `G`, `D`, `P`, `S`, `:` and so on) are skipped.

### Carriage control

The first character of every formatted record is consumed as carriage control:

| Char | Action |
|---|---|
| blank (or other) | Normal single-space advance |
| `0` | Blank line first (double space) |
| `1` | Form feed (`\f`) |
| `+` | Carriage return with no line feed (overprint) |

Start formats with `1X` or `' '` for normal output.

### Input

```fortran
      READ *, N, X
      READ (5,*) A(I), B
      READ (5,100) N
      READ 100, N
```

- **All input is list-directed** from stdin via `scanf`, whatever the format. A `? ` prompt is printed first.
- Accepted items: scalar variables, subscripted elements, and whole arrays (reads `size` values in storage order).
- Implied-DO lists and CHARACTER variables are **not** supported in READ.

---

## Interactive mode

Started when no file is given. The prompt is `Ok`.

| Command | Action |
|---|---|
| `nnn statement` | Store a program line under label `nnn`, kept sorted by label (like BASIC line numbers). Re-entering a label replaces that line. Labels also serve as GOTO/DO/FORMAT targets. |
| `statement` | Execute immediately, without storing it. |
| `RUN` | Run the stored program. |
| `LIST` | List the stored program. |
| `NEW` | Clear program, variables, FORMATs and DO stack. |
| `LOAD "file"` / `LOAD file` | Clear, then load a source file (same rules as batch mode). |
| `SAVE "file"` / `SAVE file` | Write the program to a file. |
| `EDIT`, `ED`, `AUTO` | Enter the edit submenu (below). |
| `LISTING [ON\|OFF]` | Toggle source listing and cross-reference. Bare `LISTING` reports status. |
| `TRACE [ON\|OFF]` | Toggle pseudo-object trace. Bare `TRACE` reports status. |
| `BYE`, `QUIT` | Exit with `LOGGED OFF`. |

```
Ok
10 DO 20 I = 1, 3
20 PRINT *, I, I**2
RUN
          1          1
          2          4
          3          9

EXECUTION TERMINATED.  CPU TIME: 0.00 SEC
Ok
PRINT *, 2**10
       1024
Ok
```

### Edit submenu

The edit submenu is for entering FORTRAN the natural way, where most statements carry no label:

- Lines are **appended in the order typed**; no labels are generated.
- A leading number becomes that line's label, for FORMAT statements, loop-terminating CONTINUEs, and GOTO/IF targets.
- An unlabelled `FORMAT` produces a warning (it can never be referenced) but is still stored.
- `RUN` or `EX` runs the program and leaves the submenu.
- Ctrl-Z (0x1A) or EOF leaves the submenu without running.
- Continuation markers are **not** processed here; enter each statement on one line.

---

## Listings, cross-reference and trace

### Source listing (`-l` / `LISTING ON`)

Printed before execution: a banner with program name and timestamp, then every stored line with its sequence number and label, then line and label totals.

### Cross-reference

Printed after execution. It is built by a static scan of the source, so each source line appears once per symbol no matter how many times it executed.

**Symbols** (variables, arrays, statement functions), with name, type, class and a reference list:

| Code | Meaning |
|---|---|
| `s` | Specified (DIMENSION / type declaration) |
| `/` | DATA |
| `d` | DO index |
| `=` | Assigned |
| `u` | Used |
| `i` | Input (READ) |
| `o` | Output (WRITE/PRINT) |

**Labels**:

| Code | Meaning |
|---|---|
| `s` | Defining line |
| `@` | Defining line is a FORMAT |
| `d` | DO terminal label |
| `f` | FORMAT reference in READ/WRITE/PRINT |
| `g` | GOTO target |
| `i` | Arithmetic IF target |

### Trace (`-t` / `TRACE ON`)

Each executed statement is echoed with its label, followed by the stack-machine-style operations the interpreter performed, at synthetic addresses that increase by 2:

```
 LOC   OP     OPERAND            STMT  SOURCE
                     20  PRINT *, I, I**2
 0000  LD     I
 0002  LD     I
 0004  LIT    2
 0006  PWR
 0008  PRNT   *
```

| Group | Pseudo-ops |
|---|---|
| Loads and literals | `LIT` `LITS` `LITH` `LD` `LDX` |
| Stores | `STO` `STOX` `STOSUB` |
| Arithmetic | `ADD` `SUB` `MUL` `DIV` `PWR` `CAT` `CMP` |
| Control | `JMP` `CGOTO` `AIF` `IF` `SKIPIF` `FOR` `LOOP` `ENDFOR` `CALL` `RET` `HALT` |
| I/O | `PRNT` `WRITE` `READ` |

This is an honest trace of what the interpreter did, not real machine code.

---

## Error messages

Errors print to stderr as `?Message`, or `?Message in nnn` when the current statement is labelled. Execution then stops.

| Message | Cause |
|---|---|
| `Syntax error` | Unparseable statement, or an unsupported statement (e.g. `COMMON`, `IMPLICIT`) falling through to assignment. |
| `Out of memory` | A fixed table is full (see limits). |
| `Subscript out of range` | Computed index outside the array. |
| `Array not dimensioned` | Subscript used on a scalar. |
| `Division by zero` | INTEGER divide by zero. |
| `Undefined line number` | GOTO/IF/DO target or FORMAT label not found. |
| `Undefined subroutine` | CALL to an unknown name. |
| `Undefined function` | Intrinsic dispatch failure. |
| `Illegal function call` | Intrinsic called with no arguments. |
| `Return without call` | RETURN in the main program. |
| `If without matching end if` | Block IF not closed. |
| `Function fell off end` | FUNCTION execution ran past the end of the program. |
| `Function did not return` | A single FUNCTION call exceeded 2,000,000 statements. |

---

## Capacity limits

All tables are static and fixed at compile time. Adjust the `#define`s at the top of the source file to change them.

| Limit | Value |
|---|---|
| Program lines (`MAXLINES`) | 250 |
| Variables and arrays (`MAXVARS`) | 150 |
| Line length (`LINELEN`) | 240 |
| FORMAT statements (`MAXFORMATS`) | 100 |
| Nested active DO loops (`MAXDO`) | 20 |
| Output items per I/O statement (`MAXVALS`) | 350 |
| Statement functions / arguments | 20 / 3 |
| Subprograms / arguments / call depth | 20 / 8 / 10 |
| Array dimensions | 3 |
| Identifier significance | 7 characters |
| String value length | 127 (64 for a quoted literal in an expression) |
| Computed GOTO labels | 64 |
| DATA names / values per group | 16 / 16 |

Array storage is allocated from the heap with `calloc`/`malloc` and does not count against the static tables.

---

## Deviations from standard FORTRAN

- Free-form source; blanks are significant; keywords are effectively reserved (a variable named `IF`, `DO` or `DATA` will not work).
- DO loops are one-trip (FORTRAN IV behaviour, not FORTRAN 77 zero-trip).
- INTEGER arithmetic wraps at 16 bits; INTEGER storage does not.
- `MAX1` and `MIN1` return REAL (the standard says INTEGER). `SIGN` always returns REAL.
- Hollerith constants in expressions and DATA keep only their first character.
- `E` output uses C exponent notation, and oversized fields are not filled with asterisks.
- READ is always list-directed; its FORMAT is ignored.
- I/O unit numbers are ignored.
- CHARACTER substrings are supported **only as an assignment target** on a scalar: `NAME(3:5) = 'ABC'`. Substring references in expressions are not supported.
- Comparing a string with a number treats the number as an empty string.
- Subprogram variables are global; there are no local variables or COMMON.

**Not implemented:** `COMMON`, `EQUIVALENCE`, `IMPLICIT`, `EXTERNAL`, `INTRINSIC`, `SAVE` (statement), `ENTRY`, `DOUBLE PRECISION`, `COMPLEX`, assigned GOTO / `ASSIGN`, `PAUSE`, `DO WHILE` / `END DO`, file I/O (`OPEN`, `CLOSE`, `REWIND`, `BACKSPACE`), and fixed-column source.

---

## Known issues

- **`END IF` (two words) inside a subprogram** is taken as the subprogram's `END` by the pre-scan, which truncates the body. The main program can then fall into the remainder. Use `ENDIF` inside subprograms.
- **Variables persist across `RUN`** in the REPL. Only `NEW` or `LOAD` clears them. `DATA` and `PARAMETER` statements re-execute, but other leftover values remain.
- **Statement functions are never cleared.** `NEW` does not reset them. Each `RUN` re-registers every definition and the first registration wins, so a later program redefining the same name gets the old body. Repeated runs eventually produce `Out of memory`.
- **Array storage is not freed** on `NEW`, `LOAD` or re-declaration. A long interactive session leaks heap, which matters on the 16-bit target.
- A REAL or CHARACTER variable passed to `READ` is read with `%f`. CHARACTER targets are not handled.
- The block comment at the top of `ivtran.c` is out of date: it lists subprograms and computed GOTO as unimplemented, but both are implemented.

---

## Internals

A brief map for anyone modifying the source.

| Area | Functions |
|---|---|
| Values | `VAL` holds an int, real or string; `mkint` / `mkreal` / `mkstr`; `VI` / `VF` coerce. |
| Symbols | `getvar` (auto-creates, honours call-frame aliases), `findvar`, `findvarAliased`, `declareArray`, `arrIndex`. |
| Expressions | Recursive descent: `evalLogical` → `parseAnd` → `parseNot` → `parseRelational` → `parseConcatExpr` → `parseExprTop` → `parseTerm` → `parsePower` → `parseUnary` → `parsePrimary`. It parses straight from the statement text on every execution; there is no AST. |
| Dispatch | `execOneStatement` checks keywords (loop-relevant ones first), then falls through to `doAssignOrCall`. |
| Assignment cache | `asgnCache[]` remembers per line that a statement is a plain assignment, its target `VAR*` and where the subscript/`=` begins. Repeat executions skip keyword dispatch and name lookup. The cache is cleared at the start of every run. |
| Run loop | `runFrom` → `execIndex`, which handles DO-loop closure on labelled lines. Subprogram bodies are skipped via `findSubprogAtLine`. |
| Subprograms | `prescanSubprograms`, `doCall`, `doReturn`, `callUserFunction`. The last runs a nested `execIndex` loop so a function can return a value from inside an expression. |
| Block IF | `classifyIfStmt`, `resolveIfFalse`, `findConstructEnd`. These scan forward textually; there is no precomputed jump table. |
| I/O | `parseOutList` / `parseOutItem` (implied-DO in three phases: split segments, locate control clause, evaluate); `applyFormat` / `applyFormatItems` / `applyGroupRepeat`; records are built in `recbuf` and flushed by `emitRecord`, which applies carriage control. |
| Listings | `printSourceListing`, `printCrossReference`, `lineRefCode`, `lineLabelRefCode`, `emitOp`. |

The banner and listing header strings (revision, copyright line, programmer name) are hard-coded in `printBanner` and `printSourceListing`.

