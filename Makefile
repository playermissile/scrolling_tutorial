DEST = xex/
SRC = src/
BINS = xex/course_vscroll_dlist.xex \
	xex/course_no_scroll_dlist.xex \
	xex/course_scroll_down.xex \
	xex/fine_vscroll_dlist.xex \
	xex/fine_vscroll_4.xex \
	xex/fine_vscroll_better_dlist.xex \
	xex/no_scrolling_dlist.xex \
	xex/vertical_scrolling_dlist.xex

.PHONY: png

# %.xex: %.s
# 	atasm -mae -Isrc -o$@ -L$<.var -g$<.lst $<
.s.xex:
	atasm -mae -Isrc -o$@ -L$<.var -g$<.lst $<

all: $(BINS)

xex/course_no_scroll_dlist.xex: src/course_no_scroll_dlist.s src/util_font.s src/util_scroll.s src/font_data_antic4.s
	atasm -mae -Isrc -o$@ -L$<.var -g$<.lst $<

xex/course_scroll_down.xex: src/course_scroll_down.s src/util_font.s src/util_scroll.s src/font_data_antic4.s
	atasm -mae -Isrc -o$@ -L$<.var -g$<.lst $<

xex/fine_vscroll_dlist.xex: src/fine_vscroll_dlist.s src/util_font.s src/util_scroll.s src/font_data_antic4.s
	atasm -mae -Isrc -o$@ -L$<.var -g$<.lst $<

xex/fine_vscroll_4.xex: src/fine_vscroll_4.s src/util_font.s src/util_scroll.s src/font_data_antic4.s
	atasm -mae -Isrc -o$@ -L$<.var -g$<.lst $<

xex/fine_vscroll_better_dlist.xex: src/fine_vscroll_better_dlist.s src/util_font.s src/util_scroll.s src/font_data_antic4.s
	atasm -mae -Isrc -o$@ -L$<.var -g$<.lst $<

xex/course_vscroll_dlist.xex: src/course_vscroll_dlist.s src/util_font.s src/util_scroll.s src/font_data_antic4.s
	atasm -mae -Isrc -o$@ -L$<.var -g$<.lst $<

xex/no_scrolling_dlist.xex: src/no_scrolling_dlist.s src/util_font.s src/util_scroll.s src/font_data_antic4.s
	atasm -mae -Isrc -o$@ -L$<.var -g$<.lst $<

xex/vertical_scrolling_dlist.xex: src/vertical_scrolling_dlist.s src/util_font.s src/util_scroll.s src/font_data_antic4.s
	atasm -mae -Isrc -o$@ -L$<.var -g$<.lst $<

png:
	optipng *.png

clean:
	rm -f $(BINS)
