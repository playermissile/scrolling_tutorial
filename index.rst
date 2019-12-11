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



A Refresher on Display Lists
--------------------------------------------

Display lists are an important topic for scrolling, because certain flags on
display list commands tell ANTIC which lines get scrolled and which are left
alone. For a summary, check out my :ref:`tutorial on DLIs <dli_tutorial>` which
has a large section on display list instructions. A small amount of relevant
detail is repeated here.

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

There are 14 available graphics modes, which are encoded into low 4 bits. This
tutorial is only going to focus on three of the text modes. Any mode can be
scrolled horizontally, and modes taller than 1 scan line can also be scrolled
vertically, but the combination of low memory usage and large height of the
text modes make them ideal candidates for scrolling games.

.. csv-table::

    Mode, Decimal, BASIC Mode,  Description, Scan Lines, Type, Colors
    2, 02,    0,     40 x 24,   8, text, 2
    4, 04,    n/a,   40 x 24,   8, text, 5
    5, 05,    n/a,   40 x 12,  16, text, 5

.. seealso::

   More resources about display lists are available:

   * https://www.atariarchives.org/mapping/memorymap.php#560,561
   * https://www.atariarchives.org/mapping/appendix8.php


A Crash Course on Course Scrolling
---------------------------------------

Scrolling means the display screen is a *window* on a larger map, that the user
is looking at only a small portion of the overall area, and this window can be
moved around.

Course scrolling, that is: scrolling with blocky jumps, can be accomplished
without any use of the hardware scrolling registers. In fact, course scrolling
falls out as a side-effect of the ``LMS`` bit on display list commands. Being
able to reposition the memory pointer for any display list instruction means
that you can tell ANTIC where to look in memory when it draws a scan line.
Simply by moving the address pointer to a different location, you can change
the display.

First we will look at vertical course scrolling which is the simpler case than
horizontal course scrolling. After examining horizontal course scrolling, we
will combine the two which will give us unrestricted 2D scrolling.


Definitions
~~~~~~~~~~~~~~~~~~~~~~~~~~

It helps to set up what we mean by the directions, because depending on your
perspective, **scrolling up** and **scrolling down** (and similarly **left**
and **right**) could mean exactly opposite things. Are the directions referring
to which way the data is moving on the screen? Or which way the playfield
window is moving over the larger map of data?

The convention is to refer to the direction as the way the playfield window is
moving. So, **scrolling up** means the playfield window is moving up over the
larger map, but what that means in terms of what's displayed is that new data
is appearing at the top of the screen, pushing everything else down the screen
and old data is vanishing off the bottom of the screen.



Vertical Course Scrolling
------------------------------------------

Course scrolling vertically is moving the playfield data such that the user
sees a new line of information on the top of the screen while the line that was
previously on the on the bottom of the screen moves off, and all other visible
lines move down one line. (Or vice-versa: new data appears on the bottom while
a line is removed from the top.) This direction is simpler than horizontal
because only a single ``LMS`` instruction needs to be updated, so that is where
we will start.

.. _course_no_scroll_dlist:

A Starting Point
~~~~~~~~~~~~~~~~~~~~~~~~~

Here is a display list without any scrolling, and just a single instruction
with ``LMS`` set in the main region of mode 4 lines. That ``LMS`` tells ANTIC
where to look in memory for that first line and all subsequent lines until another ``LMS`` instruction is encountered.

.. figure:: course_no_scroll_dlist.png
   :align: center
   :width: 90%

.. raw:: html

   <ul>
   <li><b>Source Code:</b> <a href="https://raw.githubusercontent.com/playermissile/scrolling_tutorial/master/src/course_no_scroll_dlist.s">course_no_scroll_dlist.s</a></li>
   <li><b>Executable:</b> <a href="https://raw.githubusercontent.com/playermissile/scrolling_tutorial/master/xex/course_no_scroll_dlist.xex">course_no_scroll_dlist.xex</a></li>
   </ul>

All this test program does is create a display list and show a simple test
pattern. There is nothing special about this display list, no scrolling bits
set on any display list instructions; only the ``LMS`` instruction to set the
initial memory location for the 22 lines of ANTIC Mode 4 that will become the
scrolling region in further examples, and another ``LMS`` for the two lines of
ANTIC mode 2 at the bottom for non-scrolling status lines.

.. code-block::

   ; Simple display list to be used as course scrolling comparison
   dlist_course_mode4
           .byte $70,$70,$70       ; 24 blank lines
           .byte $44,$00,$80       ; Mode 4 + LMS + address
           .byte 4,4,4,4,4,4,4,4   ; 21 more Mode 4 lines
           .byte 4,4,4,4,4,4,4,4
           .byte 4,4,4,4,4
           .byte $42,<static_text, >static_text ; 2 Mode 2 lines + LMS + address
           .byte $2
           .byte $41,<dlist_course_mode4,>dlist_course_mode4 ; JVB ends display list


Memory Layout
~~~~~~~~~~~~~~~~~~~~

To move a viewport window up or down over a larger map doesn't require any
difference in memory layout for the screen data, just more of it.

.. figure:: memory_layout_vertical.png
   :align: center
   :width: 50%



Course Scrolling Down
~~~~~~~~~~~~~~~~~~~~~~~~~

Scrolling down means new data is appearing at the bottom of the screen, pushing
data currently on the screen upwards and finally disappearing off the top of
the screen:

.. figure:: course_scroll_down.png
   :align: center
   :width: 90%

.. raw:: html

   <ul>
   <li><b>Source Code:</b> <a href="https://raw.githubusercontent.com/playermissile/scrolling_tutorial/master/src/course_scroll_down.s">course_scroll_down.s</a></li>
   <li><b>Executable:</b> <a href="https://raw.githubusercontent.com/playermissile/scrolling_tutorial/master/xex/course_scroll_down.xex">course_scroll_down.xex</a></li>
   </ul>

This is accomplished by updating the start address that ANTIC sees for the
first line. 

.. code-block::

   ; move viewport one line down by pointing display list start address
   ; to the address 40 bytes further in memory
   course_scroll_down
           clc
           lda dlist_course_address
           adc #40
           sta dlist_course_address
           lda dlist_course_address+1
           adc #0
           sta dlist_course_address+1
           rts

Adding 40 bytes to that address will move the starting point one
line higher in memory, moving what was the 2nd line being displayed to the
first line and a line previously off-screen to the 22nd line. This gives the
appearance of the playfield window moving down across the map.

The code needs a timing loop so the scrolling doesn't happen too fast:

.. code-block::

   loop
           ldx #15         ; number of VBLANKs to wait
   ?start  lda RTCLOK+2    ; check fastest moving RTCLOCK byte
   ?wait   cmp RTCLOK+2    ; VBLANK will update this
           beq ?wait       ; delay until VBLANK changes it
           dex             ; delay for a number of VBLANKs
           bpl ?start
   
           ; enough time has passed, scroll one line
           jsr course_scroll_down
   
           jmp loop

This delay loop simply waits for a number of vertical blank intervals to pass,
then updates the screen memory pointer.



Course Scrolling Up
~~~~~~~~~~~~~~~~~~~~~~~~~

Scrolling up means new data is appearing at the top of the screen, pushing data
currently on the screen downwards and finally disappearing off the bottom of
the screen:

.. figure:: course_scroll_up.png
   :align: center
   :width: 90%

.. raw:: html

   <ul>
   <li><b>Source Code:</b> <a href="https://raw.githubusercontent.com/playermissile/scrolling_tutorial/master/src/course_scroll_up.s">course_scroll_up.s</a></li>
   <li><b>Executable:</b> <a href="https://raw.githubusercontent.com/playermissile/scrolling_tutorial/master/xex/course_scroll_up.xex">course_scroll_up.xex</a></li>
   </ul>

This is accomplished using exactly the same method of changing the start
address that ANTIC uses for the screen memory:

.. code-block::

   ; move viewport one line down by pointing display list start address
   ; to the address 40 bytes further in memory
   course_scroll_down
           clc
           lda dlist_course_address
           adc #40
           sta dlist_course_address
           lda dlist_course_address+1
           adc #0
           sta dlist_course_address+1
           rts

But instead of adding 40 bytes, we subtract 40 bytes from the address to move
the starting point one line prior in memory, moving what was the 1st line being
displayed to the 2nd line and a line previously off-screen to the 1st line.
This gives the appearance of the playfield window moving up across the map.




Horizontal Course Scrolling
------------------------------------------

Horizontal course scrolling is only slightly more complicated than vertical
course scrolling because multiple ``LMS`` addresses need to be updated.



Memory Layout
~~~~~~~~~~~~~~~~~~~~

Scrolling left and right does present a different problem, because if only the
first ``LMS`` address is updated, a subsequent line will use memory immediately
following the previous line, resulting in a snake-like movement that doesn't
resemble scrolling.

To remedy this, the memory should be thought of as individual horizontal
strips, which for ANTIC to process correctly requires ``LMS`` addresses on
every display list line in the scrolling region.

.. figure:: memory_layout_horizontal.png
   :align: center
   :width: 80%



Combined Horizontal and Vertical Course Scrolling
--------------------------------------------------


Memory Layout
~~~~~~~~~~~~~~~~~~~~

Perhaps not surprisingly, combining horizontal and vertical scrolling requires combining the memory layout ideas: wide horizontal lines coupled with lines above and below the viewport.

.. figure:: memory_layout_2d.png
   :align: center
   :width: 80%




A Crash Course on Vertical Fine Scrolling
-----------------------------------------------

Vertical fine scrolling is controlled by ANTIC's ``VSCROL`` hardware register.
The register can be any number from 0 - 15 representing the number of scan
lines to scroll. ANTIC accomplishes scrolling not by moving the display list up
and down by a number of scan lines, but by using the ``VSCROL`` value to *skip*
that number of scan lines in the first line of the display list, essentially
shortening the number of displayed lines.

This will become more clear with an example. First, let's see what happens just
by turning on the vertical scrolling bit on a display list.

First Display List With Scrolling
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Here's the same program used in the :ref:`course vertical scrolling
<course_no_scroll_dlist>` section, except now the vertical scrolling bit has
been set on the display list instructions for the scrolling region of lines A
through V. Notice the first line of the mode 2 status lines at he bottom seems
to be missing! Actually, it is still there, or more correctly: one scan line of
it is still there.

.. figure:: fine_vscroll_dlist.png
   :align: center
   :width: 90%

.. raw:: html

   <ul>
   <li><b>Source Code:</b> <a href="https://raw.githubusercontent.com/playermissile/scrolling_tutorial/master/src/fine_vscroll_dlist.s">fine_vscroll_dlist.s</a></li>
   <li><b>Executable:</b> <a href="https://raw.githubusercontent.com/playermissile/scrolling_tutorial/master/xex/fine_vscroll_dlist.xex">fine_vscroll_dlist.xex</a></li>
   </ul>

Note that the ``VSCROL`` hardware register is set to zero. Here's the display list:

.. code-block::

   ; Simple display list to be used as course scrolling comparison
   dlist_course_mode4
           .byte $70,$70,$70       ; 24 blank lines
           .byte $44,$00,$80       ; Mode 4 + LMS + address
           .byte $64,$00,$80       ; Mode 4 + VSCROLL + LMS + address
           .byte $24,$24,$24,$24,$24,$24,$24,$24   ; 21 more Mode 4 + VSCROLL lines
           .byte $24,$24,$24,$24,$24,$24,$24,$24
           .byte $24,$24,$24,$24,$24
           .byte $42,<static_text, >static_text ; 2 Mode 2 lines + LMS + address
           .byte $2
           .byte $41,<dlist_course_mode4,>dlist_course_mode4 ; JVB ends display list

So what is the mystery of the (mostly) missing mode 2 line at the bottom? ANTIC
uses the first scan line that doesn't have the vertical scrolling bit set as a
sort-of *buffer zone* to the scrolling region.

Here's the same example, except the ``VSCROL`` register is set to 4:

.. figure:: fine_vscroll_4.png
   :align: center
   :width: 90%

where it shows that 4 scan lines of line A have been scrolled off the screen
**and** the first ANTIC mode 2 line shows 4 of its 8 scan lines.

ANTIC's Vertical Scrolling Buffer Zone
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``VSCROL`` hardware register controls how many scan lines are shifted for
fine scrolling. The value tells ANTIC on which scan line to start rendering for
the first display list instruction it encounters with the vertical scrolling
bit set. Subsequent lines in the display list that have the vertical scrolling
bit set are fully rendered, but because that initial scan line was rendered
with fewer scan lines, the display has appeared to move up.

What confused the author until reading section 4.7 in the `Altirra Hardware Reference Manual <http://www.virtualdub.org/downloads/Altirra%20Hardware%20Reference%20Manual.pdf>`_
is that ``VSCROL`` value also controls where ANTIC *stops* rendering on that
*buffer zone* display list instruction: it renders scan lines up to and
including that value.

In the first example, ``VSCROL = 0``. ANTIC mode 4 lines are 8 scan lines tall,
and for scrolling purposes the height of a mode line is enumerated from 0, so
an 8 scan line tall text mode has scan lines numbered 0 through 7. For the
example, the rendering of line A starts at scan line zero of the text mode. The
buffer zone mode 2 line that is only rendered with a single scan line: it
stopped rendering after rendering scan line zero of that mode 2 line.

The second example uses ``VSCROL`` set to 4, here shown in detail:


.. figure:: detail_vscrol_4.png
   :align: center
   :width: 80%

The first display list line with the vertical scrolling bit set, Line A, is
rendered starting from scan line 4 (again, as enumerated from zero: scan lines
0, 1, 2, and 3 are skipped and 4, 5, 6, and 7 are rendered). All subsequent
lines with their vertical scroll bit set have all 8 scan lines rendered. The
buffer zone, that is: the first display list line without the scroll bit set,
is rendered *through* scan line 4 as enumerated from zero, so scan lines 0, 1,
2, 3, and 4. Scan lines 5 through 7 are not rendered.


Fixing the Last Scrolled Line
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Having the scrolled region extend into the status lines at the bottom of the
previous example is obviously not what's intended. This example fixes that
problem:

.. figure:: fine_vscroll_better_dlist.png
   :align: center
   :width: 90%

.. raw:: html

   <ul>
   <li><b>Source Code:</b> <a href="https://raw.githubusercontent.com/playermissile/scrolling_tutorial/master/src/fine_vscroll_better_dlist.s">fine_vscroll_better_dlist.s</a></li>
   <li><b>Executable:</b> <a href="https://raw.githubusercontent.com/playermissile/scrolling_tutorial/master/xex/fine_vscroll_better_dlist.xex">fine_vscroll_better_dlist.xex</a></li>
   </ul>

The solution is to clear the vertical scrolling bit on the final mode 4 line in
the scrolling region. Here's the new display list with only a single byte
changed: the final ``$24`` in the previous example is changed to a normal mode
4 line:

.. code-block::

   ; Simple display list to be used as course scrolling comparison
   dlist_course_mode4
           .byte $70,$70,$70       ; 24 blank lines
           .byte $44,$00,$80       ; Mode 4 + LMS + address
           .byte $64,$00,$80       ; Mode 4 + VSCROLL + LMS + address
           .byte $24,$24,$24,$24,$24,$24,$24,$24   ; 20 more Mode 4 + VSCROLL lines
           .byte $24,$24,$24,$24,$24,$24,$24,$24
           .byte $24,$24,$24,$24
           .byte 4                 ; and the final Mode 4 without VSCROLL
           .byte $42,<static_text, >static_text ; 2 Mode 2 lines + LMS + address
           .byte $2
           .byte $41,<dlist_course_mode4,>dlist_course_mode4 ; JVB ends display list

This leaves the status lines with two complete mode 2 lines, and the scrolling
playfield as 21 mode 4 lines, and a one line *buffer zone*, this time of mode
4. In this case, ``VSCROL = 4``, so the first scrolled line is rendered
starting at its scan line 4 and the buffer zone line is rendered through its
scan line 4, we are missing 7 scan lines from the same display list without any
vertical scrolling bits.

.. note:: The number of scan lines ANTIC will generate is reduced by vertical scrolling. The total number of scan lines can be counted by setting ``VSCROL = 0``, meaning the buffer zone line will be reduced to a single scan line. Changes to ``VSCROL`` don't change the total number of lines generated, for instance: setting ``VSCROL = 2`` reduces the first scrolled line to 6 scan lines but increases the buffer zone to 3 scan lines, resulting in the same net number of scan lines in the scrolling + buffer zone regions.


Continuous Fine Scrolling
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


This technique of waiting until the the vertical blank has *just* passed will
ensure that the display list address isn't changed while ANTIC isn't in the
middle of drawing the screen.

.. note:: Strictly speaking, this isn't necessary because ANTIC will not go back and re-read the LMS address of a previously processed display list command. Changing the LMS in the middle screen in this case would only have the effect




A Crash Course on Horizontal Fine Scrolling
------------------------------------------------------




A Crash Course on Combined Fine Scrolling
--------------------------------------------------



Interlude: Vertical Blank Interrupts
------------------------------------------------


A Fine Scrolling Engine
------------------------------
