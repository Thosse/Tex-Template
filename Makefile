# =============================================================================
#  Makefile — LaTeX Dual-Output Workflow (LaTeXML Edition)
#  Defines the automation for generating both high-quality print PDFs and
#  modern responsive HTML5 documents from a unified LaTeX source.
# =============================================================================

# ── Paths & Directories ──────────────────────────────────────────────────────
# Organizing the project structure to keep source files and build artifacts separate.
SRC_DIR     := src
BUILD_DIR   := build
RESULT_DIR  := res
HTML_DIR    := $(RESULT_DIR)/html
FIG_TIKZ    := figures/tikz
FIG_BUILD   := figures/build
SCRIPTS_DIR := scripts

# Main document entry points

MAIN_BASE   := main
MAIN        := $(SRC_DIR)/$(MAIN_BASE).tex

# ── Tools & Binaries ─────────────────────────────────────────────────────────
# Standard TeX live and LaTeXML executables with optimal flags for automation.
PDFLATEX    := pdflatex -interaction=nonstopmode -halt-on-error
LATEXML     := latexml
LATEXMLPOST := latexmlpost
PDF2SVG     := pdf2svg
BIBTEX      := bibtex

# ── Vector Graphics Resolution (TikZ Assets) ────────────────────────────────
# Automatically discovers all standalone TikZ files and maps them to dual targets.
# PDF is utilized for pdflatex compilation; SVG provides scalable web graphics.
TIKZ_SRCS   := $(wildcard $(FIG_TIKZ)/*.tex)
FIG_PDFS    := $(patsubst $(FIG_TIKZ)/%.tex, $(FIG_BUILD)/%.pdf, $(TIKZ_SRCS))
FIG_SVGS    := $(patsubst $(FIG_TIKZ)/%.tex, $(FIG_BUILD)/%.svg, $(TIKZ_SRCS))

# ── Phony Targets ────────────────────────────────────────────────────────────
# Explicitly declaring pseudo-targets to prevent conflicts with matching file names.
.PHONY: all figures pdf html watch clean clean-build clean-figures clean-tex help

# Default target: Compiles everything (Graphics -> PDF -> HTML)
all: figures pdf html

# ── Directory Generation ─────────────────────────────────────────────────────
# Order-only prerequisites ensuring directories exist before compilation starts.
# Automatically matches any path ending in a slash and creates it on demand.
%/:
	mkdir -p $@


# ── Graphics Pipeline ────────────────────────────────────────────────────────
# Meta-target processing all externalized standalone TikZ assets.
figures: $(FIG_PDFS) $(FIG_SVGS)

# Step A: Compiles raw standalone TikZ code into cropped individual PDFs
$(FIG_BUILD)/%.pdf: $(FIG_TIKZ)/%.tex | $(FIG_BUILD)/
	@echo "  [TikZ→PDF]  $<"
	$(PDFLATEX) -output-directory $(FIG_BUILD) $<

# Step B: Converts the generated PDF into an optimized SVG for responsive web views
$(FIG_BUILD)/%.svg: $(FIG_BUILD)/%.pdf
	@echo "  [PDF→SVG]   $@"
	$(PDF2SVG) $< $@

# ── PDF Document Compilation ─────────────────────────────────────────────────
# Full production pipeline including dynamic citation parsing via BibTeX (3 passes required)
pdf: figures | $(BUILD_DIR)/ $(RESULT_DIR)/
	@echo "  [PDF run 1]"
	$(PDFLATEX) -output-directory $(BUILD_DIR) $(SRC_DIR)/$(MAIN_BASE).tex
#   @echo "  [BibTeX]"
#	cd $(BUILD_DIR) && $(BIBTEX) $(MAIN_BASE)
	@echo "  [PDF run 2]"
	$(PDFLATEX) -output-directory $(BUILD_DIR) $(SRC_DIR)/$(MAIN_BASE).tex
	@echo "  [PDF run 3]"
	$(PDFLATEX) -output-directory $(BUILD_DIR) $(SRC_DIR)/$(MAIN_BASE).tex
	@# Copy the finished PDF up to the main build folder, leaving logs behind
	@cp $(BUILD_DIR)/$(MAIN_BASE).pdf $(RESULT_DIR)/$(MAIN_BASE).pdf
	@echo "  ✓ PDF (with BibTeX) generated: $(BUILD_DIR)/$(MAIN_BASE).pdf"

# ── HTML5 Document Compilation (LaTeXML Pipeline) ───────────────────────────
# Converts TeX sources into cross-platform accessible web files.
html: figures | $(BUILD_DIR)/ $(HTML_DIR)/
	@echo "  [LaTeXML]   $(MAIN_BASE).tex"
	@# Stage 1: Parse LaTeX into semantically structured XML.
	@# The babel bypass option is active to prevent standard package runtime crashes.
	$(LATEXML) \
		--dest=$(BUILD_DIR)/$(MAIN_BASE).xml \
		--log=$(BUILD_DIR)/$(MAIN_BASE).latexml.log \
		$(SRC_DIR)/$(MAIN_BASE).tex
		
	@# Stage 2: Transform XML to validated HTML5 markup.
	@# Injects custom styles and loads the CDN-backed MathJax processor for equations.
	@# Note: --css takes a path relative to the final HTML file location.
	$(LATEXMLPOST) \
		--format=html5 \
		--css=$(SCRIPTS_DIR)/custom.css \
		--javascript=$(SCRIPTS_DIR)/mathjax.js \
		--log=$(BUILD_DIR)/$(MAIN_BASE).latexmlpost.log \
		--dest=$(HTML_DIR)/$(MAIN_BASE).html \
		$(BUILD_DIR)/$(MAIN_BASE).xml
		
	@echo "  ✓ HTML generated: $(BUILD_DIR)/$(MAIN_BASE).html"

# ── Continuous Automation ────────────────────────────────────────────────────
# Development loop using 'entr'. Automatically rebuilds assets on source changes.
watch:
	@echo "  Watching $(SRC_DIR)/ and $(FIG_TIKZ)/ — Press Ctrl+C to stop"
	find $(SRC_DIR) $(FIG_TIKZ) -name '*.tex' | entr -c make all

# ── Cleanup Operations ───────────────────────────────────────────────────────
# Deletes individual standalone graphics build directories.
clean-figures:
	@echo "  [clean]     Sub-directory $(FIG_BUILD)/"
	rm -rf $(FIG_BUILD)

# Deletes document compilation output.
clean-build:
	@echo "  [clean]     Sub-directory $(BUILD_DIR)/"
	rm -rf $(BUILD_DIR) $(RESULT_DIR)

# Radical cleanup removing all compiled targets and miscellaneous TeX log artifacts.
clean-tex:
	@echo "  [clean]     Residual LaTeX workspace artifacts"
	rm -f $(SRC_DIR)/*.aux $(SRC_DIR)/*.log $(SRC_DIR)/*.toc \
	      $(SRC_DIR)/*.out $(SRC_DIR)/*.lof $(SRC_DIR)/*.lot \
	      $(SRC_DIR)/*.xml $(SRC_DIR)/*.html $(SRC_DIR)/*.css

clean: clean-tex clean-build clean-figures
	@echo "  [clean]     Finished"

# ── Documented Interface Helper ──────────────────────────────────────────────
# Prints explicit usage hints when executing plain 'make help'.
help:
	@echo ""
	@echo "  LaTeX Dual-Output Workflow (LaTeXML Edition)"
	@echo "  ─────────────────────────────────────────────"
	@echo "  make                Compiles assets, print PDF, and accessible HTML5"
	@echo "  make figures        Compiles standalone TikZ assets only (PDF + SVG)"
	@echo "  make pdf            Generates print document with active BibTeX citations"
	@echo "  make html           Generates web asset targets only (via LaTeXML parsing)"
	@echo "  make watch          Monitors workspace files and live-rebuilds via 'entr'"
	@echo "  make clean    		 Complete workspace purge including any cached files"
	@echo "  make clean-build    Purges the main document build directory ($(BUILD_DIR)/)"
	@echo "  make clean-figures  Purges the vector graphics build directory ($(FIG_BUILD)/)"
	@echo "  make clean-tex      Purges cached files in source directory ($(SRC_DIR)/)"
	@echo ""