TARGET       ?= main
DIFF_COMMIT  ?= HEAD^

BIBLIO       := main.bib

BUILD_DIR    := build
STY_DIR      := sty

# All the source files
TEX_SOURCES  := $(wildcard headers/*.tex) $(wildcard sections/*.tex) $(wildcard *.tex) $(wildcard tables/*.tex)
IMG_SOURCES  := $(wildcard images-src/*.drawio)
PLT_SOURCES  := $(wildcard plots-src/*.plot) $(wildcard plots-src/*.txt)
LST_SOURCES  := $(wildcard listings/*)

# These are used in the paper
PLAIN_IMG    := $(wildcard images-plain/*.png)
DRAW_IMG     := $(patsubst images-src/%.drawio,images/%.pdf,$(IMG_SOURCES))
PLOT_IMG     := $(patsubst plots-src/%.plot,plots/%.tex,$(PLT_SOURCES))

# These are used for other purposes (e.g. the presentation)
DRAW_IMG_PNG := $(patsubst images-src/%.drawio,images/%.png,$(IMG_SOURCES))
DRAW_IMG_SLIDES := $(patsubst images-src/%.drawio,images-slides/%.png,$(IMG_SOURCES))

ALL_SOURCES  := $(TEX_SOURCES) $(IMG_SOURCES) $(PLT_SOURCES) $(LST_SOURCES) $(PLAIN_IMG) $(BIBLIO)
TARGET_DEPS  := $(TEX_SOURCES) $(LST_SOURCES) $(PLAIN_IMG) $(DRAW_IMG) $(PLOT_IMG) $(BIBLIO)

# Compilation Option
BTEX := --bibtex-args="-min-crossrefs=99"
LTEX := --latex-args="-synctex=1 --shell-escape -file-line-error -interaction=nonstopmode"

DRAWIO := drawio


.PHONY:
all: $(TARGET).pdf

$(TARGET).pdf: $(TARGET_DEPS)

.PHONY:
png-images: $(DRAW_IMG_PNG)

.PHONY:
images-slides: $(DRAW_IMG_SLIDES)

%.pdf: %.tex $(BIBLIO)
	TEXINPUTS=$(STY_DIR): ./bin/latexrun $(LTEX) $(BTEX) -O $(BUILD_DIR) $<
	cp $(BUILD_DIR)/$@ $@

$(BUILD_DIR)/$(TARGET).aux:
	@make $(all)

bibexport.bib: $(BUILD_DIR)/$(TARGET).aux
	bibexport -ns -o $@ $<

images/%.pdf: images-src/%.drawio
	@mkdir -p $(dir $@)
	$(DRAWIO) -x -o $@ -f pdf -b 15 --crop $<

images/%.png: images-src/%.drawio
	@mkdir -p $(dir $@)
	$(DRAWIO) -x -o $@ -f png -b 15 -s 4 --crop $<

images-slides/%.png: images-src/%.drawio
	@mkdir -p $(dir $@)
	$(eval TMP := $(shell mktemp))
	cat $< | sed 's|Times New Roman|Helvetica|g' > $(TMP)  # TODO
	$(DRAWIO) -x -o $@ -f png -b 15 -s 4 --crop $(TMP)
	rm -rf $(TMP)

plots/%.tex: plots-src/%.plot
	gnuplot -e 'set terminal epslatex' -e 'set output "$@"' $<

.PHONY:
diff: $(TARGET_DEPS)
	@bin/diff.sh $(TARGET) $(DIFF_COMMIT)

.PHONY:
clean:
	./bin/latexrun -O $(BUILD_DIR) --clean-all
	rm -rf images images-slides plots
	rm -fr _minted-*
	rm -fr $(BUILD_DIR)
	rm -f diff.pdf

.PHONY:
distclean: clean
	rm -f $(TARGET).pdf

.PHONY:
loop:
	- make $(BUILD_TARGET)
	while true; do make wait-sources > /dev/null; make $(BUILD_TARGET); done

.PHONY:
wait-sources:
	inotifywait -r -e MODIFY $(ALL_SOURCES); true
