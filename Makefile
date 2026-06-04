# =============================================================
#  Makefile — LaTeX Dual-Output Workflow
#  Targets: all, figures, pdf, pdf-full, html, watch,
#           clean, distclean, figures-clean
# =============================================================

# ── Pfade ────────────────────────────────────────────────────
SRC_DIR     := src
BUILD_DIR   := build
FIG_TIKZ    := figures/tikz
FIG_BUILD   := figures/build
SCRIPTS_DIR := scripts

MAIN        := $(SRC_DIR)/main.tex
MAIN_BASE   := main

# ── Werkzeuge ────────────────────────────────────────────────
PDFLATEX    := pdflatex -interaction=nonstopmode -halt-on-error
MAKE4HT     := make4ht
PDF2SVG     := pdf2svg
BIBTEX      := bibtex

# ── TikZ-Quellen und abgeleitete Ziele ───────────────────────
TIKZ_SRCS   := $(wildcard $(FIG_TIKZ)/*.tex)
FIG_PDFS    := $(patsubst $(FIG_TIKZ)/%.tex, $(FIG_BUILD)/%.pdf, $(TIKZ_SRCS))
FIG_SVGS    := $(patsubst $(FIG_TIKZ)/%.tex, $(FIG_BUILD)/%.svg, $(TIKZ_SRCS))

# ── Standardziel ─────────────────────────────────────────────
.PHONY: all figures pdf pdf-full html watch clean distclean figures-clean help

all: figures pdf html

# ── Verzeichnisse anlegen ────────────────────────────────────
$(BUILD_DIR)/:
	mkdir -p $@

$(FIG_BUILD)/:
	mkdir -p $@

# ── Figuren bauen ─────────────────────────────────────────────
figures: $(FIG_PDFS) $(FIG_SVGS)

# Einzelne TikZ-Datei → PDF
$(FIG_BUILD)/%.pdf: $(FIG_TIKZ)/%.tex | $(FIG_BUILD)/
	@echo "  [TikZ→PDF]  $<"
	$(PDFLATEX) -output-directory $(FIG_BUILD) $<

# PDF → SVG
$(FIG_BUILD)/%.svg: $(FIG_BUILD)/%.pdf
	@echo "  [PDF→SVG]   $@"
	$(PDF2SVG) $< $@

# ── PDF-Ausgabe ───────────────────────────────────────────────
pdf: figures | $(BUILD_DIR)/
	@echo "  [PDF run 1] $(MAIN)"
	cd $(SRC_DIR) && $(PDFLATEX) -output-directory ../$(BUILD_DIR) $(MAIN_BASE).tex
	@echo "  [PDF run 2] $(MAIN)"
	cd $(SRC_DIR) && $(PDFLATEX) -output-directory ../$(BUILD_DIR) $(MAIN_BASE).tex
	@echo "  ✓ PDF: $(BUILD_DIR)/$(MAIN_BASE).pdf"

# PDF mit BibTeX (3 Läufe)
pdf-full: figures | $(BUILD_DIR)/
	@echo "  [PDF run 1]"
	cd $(SRC_DIR) && $(PDFLATEX) -output-directory ../$(BUILD_DIR) $(MAIN_BASE).tex
	@echo "  [BibTeX]"
	cd $(BUILD_DIR) && $(BIBTEX) $(MAIN_BASE)
	@echo "  [PDF run 2]"
	cd $(SRC_DIR) && $(PDFLATEX) -output-directory ../$(BUILD_DIR) $(MAIN_BASE).tex
	@echo "  [PDF run 3]"
	cd $(SRC_DIR) && $(PDFLATEX) -output-directory ../$(BUILD_DIR) $(MAIN_BASE).tex
	@echo "  ✓ PDF (mit BibTeX): $(BUILD_DIR)/$(MAIN_BASE).pdf"

# ── HTML-Ausgabe ──────────────────────────────────────────────
html: figures | $(BUILD_DIR)/
	@echo "  [make4ht]   $(MAIN)"
	cd $(SRC_DIR) && $(MAKE4HT) \
	    --output-dir ../$(BUILD_DIR) \
	    --config ../$(SCRIPTS_DIR)/make4ht.cfg \
	    $(MAIN_BASE).tex
	@# CSS ins Build-Verzeichnis kopieren (make4ht erwartet es dort)
	cp $(SCRIPTS_DIR)/custom.css $(BUILD_DIR)/custom.css
	@echo "  ✓ HTML: $(BUILD_DIR)/$(MAIN_BASE).html"

# ── Auto-Rebuild (benötigt entr) ──────────────────────────────
watch:
	@echo "  Watching $(SRC_DIR)/ and $(FIG_TIKZ)/ — Ctrl+C zum Beenden"
	find $(SRC_DIR) $(FIG_TIKZ) -name '*.tex' | entr -c make all

# ── Aufräumen ─────────────────────────────────────────────────
clean-doc:
	@echo "  [clean] $(BUILD_DIR)/"
	rm -rf $(BUILD_DIR)

clean-fig:
	@echo "  [clean] $(FIG_BUILD)/"
	rm -rf $(FIG_BUILD)

clean: clean-doc clean-fig
	@echo "  [clean] LaTeX-Temporärdateien"
	rm -f $(SRC_DIR)/*.aux $(SRC_DIR)/*.log $(SRC_DIR)/*.toc \
	      $(SRC_DIR)/*.out $(SRC_DIR)/*.lof $(SRC_DIR)/*.lot \
	      $(SRC_DIR)/*.html $(SRC_DIR)/*.css $(SRC_DIR)/*.4ct \
	      $(SRC_DIR)/*.4tc $(SRC_DIR)/*.idv $(SRC_DIR)/*.lg  \
	      $(SRC_DIR)/*.xref $(SRC_DIR)/*.tmp $(SRC_DIR)/*.dvi

# ── Hilfe ─────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  LaTeX Dual-Output Workflow"
	@echo "  ─────────────────────────────────────────"
	@echo "  make            Figuren + PDF + HTML"
	@echo "  make figures    nur TikZ-Figuren (PDF + SVG)"
	@echo "  make pdf        nur PDF (2 LaTeX-Läufe)"
	@echo "  make pdf-full   PDF mit BibTeX (3 Läufe)"
	@echo "  make html       nur HTML (make4ht)"
	@echo "  make watch      Auto-Rebuild via entr"
	@echo "  make clean      build/ löschen"
	@echo "  make distclean  + Temp-Dateien löschen"
	@echo "  make figures-clean  figures/build/ leeren"
	@echo ""
