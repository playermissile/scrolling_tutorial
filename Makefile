DEST = xex/
SRC = src/
BINS = xex/no_scrolling_dlist.xex xex/vertical_scrolling_dlist.xex

.PHONY: png

# %.xex: %.s
# 	atasm -mae -Isrc -o$@ -L$<.var -g$<.lst $<
.s.xex:
	atasm -mae -Isrc -o$@ -L$<.var -g$<.lst $<

all: $(BINS)

xex/no_scrolling_dlist.xex: src/no_scrolling_dlist.s src/util_font.s src/util_scroll.s src/font_data_antic4.s
	atasm -mae -Isrc -o$@ -L$<.var -g$<.lst $<

xex/vertical_scrolling_dlist.xex: src/vertical_scrolling_dlist.s src/util_font.s src/util_scroll.s src/font_data_antic4.s
	atasm -mae -Isrc -o$@ -L$<.var -g$<.lst $<

png:
	optipng *.png

clean:
	rm -f $(BINS)
