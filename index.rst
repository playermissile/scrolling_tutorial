.. _scrolling_tutorial:

.. highlight:: ca65


A Crash Course on Fine Scrolling
=================================================================

.. centered:: **Atari 8-bit Fine Scrolling: A Tutorial**

**Revision 0, updated 5 Dec 2019**

This is a tutorial on fine scrolling for the Atari 8-bit series of computers.
In a nutshell, the ANTIC coprocessor provides 2D hardware scrolling at very
little computational expense.

This is advanced programming tutorial in the sense that the examples will be
written in assembly language, so the assumption will be that you are
comfortable with that. All the examples here are assembled using the
MAC/65-compatible assembler `ATasm
<https://atari.miribilist.com/atasm/index.html>`_ (and more specifically to
this tutorial, the version built-in to `Omnivore
<https://github.com/robmcmullen/omnivore>`_).

.. note:: All source code and XEX files are available in the `scrolling_tutorial source code repository <https://github.com/playermissile/scrolling_tutorial>`_ on github.



A Crash Course on Display Lists
--------------------------------

Display lists are an important topic for scrolling, because certain flags on
display list commands tell ANTIC which lines get scrolled and which are left
alone. For a summary, check out my :ref:`tutorial on DLIs <dli_tutorial>` which
has a large section on display list instructions.

A small amount of relevant detail is repeated here, though:

Display List Instruction Set
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

An ANTIC display list instruction consists of 1 byte with an optional 2 byte
address. There are 3 types of instructions: blank lines, graphics modes, and
jump instructions. Instructions are encoded into the byte using a bitmask
where low 4 bits encode the graphics mode or feature and the high 4 bits
encode the flags that affect that instruction:

  +-----+-----+---------+---------+-----+-----+-----+-----+
  |  7  |  6  |  5      |    4    |  3  |  2  |  1  |  0  |
  +-----+-----+---------+---------+-----+-----+-----+-----+
  | DLI | LMS | VSCROLL | HSCROLL |  Mode                 |
  +-----+-----+---------+---------+-----+-----+-----+-----+

The 4 flags are:

 * DLI (``$80``): enable a display list interrupt when processing this instruction
 * LMS (``$40``): trigger a Load Memory Scan, changing where ANTIC looks for screen data, and requires an additional 2 byte address immediately following this instruction byte.
 * VSCROLL (``$20``): enable vertical scrolling for this mode line
 * HSCROLL (``$10``): enable horizontal scrolling for this mode line

The 14 available graphics modes are encoded into low 4 bits using values as shown
in this table:

.. csv-table::

    Mode, Decimal, BASIC Mode,  Description, Scan Lines, Type, Colors
    2, 02,    0,     40 x 24,   8, text, 2
    3, 03,    n/a,   40 x 19,  10, text, 2
    4, 04,    n/a,   40 x 24,   8, text, 4
    5, 05,    n/a,   40 x 12,  16, text, 4
    6, 06,    1,     20 x 24,   8, text, 5
    7, 07,    2,     20 x 12,  16, text, 5
    8, 08,    3,     40 x 24,   8, bitmap, 4
    9, 09,    4,     80 x 48,   4, bitmap, 2
    A, 10,    5,     80 x 48,   4, bitmap, 4
    B, 11,    6,    160 x 96,   2, bitmap, 2
    C, 12,    n/a,  160 x 192,  1, bitmap, 2
    D, 13,    7,    160 x 96,   2, bitmap, 4
    E, 14,    n/a,  160 x 192,  1, bitmap, 4
    F, 15,    8,    320 x 192,  1, bitmap*, 2

*mode F is also used as the basis for the GTIA modes (BASIC Graphics modes 9,
10, & 11), but this is a topic outside the scope of this tutorial.

Blank lines are encoded as a mode value of zero, the bits 6, 5, and 4 taking
the meaning of the number of blank lines rather than LMS, VSCROLL, and
HSCROLL. Note that the DLI bit is still available on blank lines, as bit 7 is
not co-opted by the blank line instruction.

.. csv-table:: Blank Line Instructions

    Hex, Decimal, Blank Lines
    0, 0, 1
    10, 16, 2
    20, 32, 3
    30, 48, 4
    40, 64, 5
    50, 80, 6
    60, 96, 7
    70, 112, 8

Jumps provide the capability to split a display list into multiple parts in
different memory locations. They are encoded using a mode value of one, and
require an additional 2 byte address where ANTIC will look for the next display
list instruction. If bit 6 is also set, it becomes the Jump and wait for Vertical
Blank (JVB) instruction, which is how ANTIC knows that the display list is
finished. The DLI bit may also be set on a jump instruction, but if set on the
JVB instruction it triggers a DLI on every scan line from there until the
vertical blank starts on the 249th scan line.

.. note::

   Apart from the ``$41`` JVB instruction, splitting display lists using other
   jumps like the ``$01`` instruction is not common. It has a side-effect of
   producing a single blank line in the display list.

The typical method to change the currently active display list is to change the
address stored at ``SDLSTL`` (in low byte/high byte format in addresses
``$230`` and ``$231``). At the next vertical blank, the hardware display list
at ``DLISTL`` (``$d402`` and ``$d403``) will be updated with the values stored
here and the screen drawing will commence using the new display list.

.. seealso::

   More resources about display lists are available:

   * https://www.atariarchives.org/mapping/memorymap.php#560,561
   * https://www.atariarchives.org/mapping/appendix8.php


A Crash Course on Vertical Blank Interrupts
------------------------------------------------


A Crash Course on Course Scrolling
---------------------------------------


Vertical Course Scrolling
------------------------------------------




Horizontal Course Scrolling
------------------------------------------



Combined Horizontal and Vertical Course Scrolling
--------------------------------------------------



A Crash Course on Fine Scrolling
---------------------------------------



Vertical Fine Scrolling
------------------------------------------




Horizontal Fine Scrolling
------------------------------------------




Combined Horizontal and Vertical Fine Scrolling
--------------------------------------------------

