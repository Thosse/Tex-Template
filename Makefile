# =============================================================================
#  Makefile — LaTeX Dual-Output Workflow (LaTeXML Edition)
#  Defines the automation for generating both high-quality print PDFs and
#  modern responsive HTML5 documents from a unified LaTeX source.
# =============================================================================

# ── Paths & Directories ──────────────────────────────────────────────────────
# Organizing the project structure to keep source files and build artifacts separate.
SRC_DIR     := src
BUILD_DIR   := build
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
.PHONY: all figures pdf pdf-full html watch clean distclean figures-clean help

# Default target: Compiles everything (Graphics -> PDF -> HTML)
all: figures pdf html

# ── Directory Generation ─────────────────────────────────────────────────────
# Order-only prerequisites ensuring directories exist before compilation starts.
$(BUILD_DIR)/:
	mkdir -p $@

$(FIG_BUILD)/:
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
# Standard double-pass target to resolve dynamic section headers and table of contents.
pdf: figures | $(BUILD_DIR)/
	@echo "  [PDF run 1] $(MAIN)"
	cd $(SRC_DIR) && $(PDFLATEX) -output-directory ../$(BUILD_DIR) $(MAIN_BASE).tex
	@echo "  [PDF run 2] $(MAIN)"
	cd $(SRC_DIR) && $(PDFLATEX) -output-directory ../$(BUILD_DIR) $(MAIN_BASE).tex
	@echo "  ✓ PDF generated: $(BUILD_DIR)/$(MAIN_BASE).pdf"

# Full production pipeline including dynamic citation parsing via BibTeX (3 passes required)
pdf-full: figures | $(BUILD_DIR)/
	@echo "  [PDF run 1]"
	cd $(SRC_DIR) && $(PDFLATEX) -output-directory ../$(BUILD_DIR) $(MAIN_BASE).tex
	@echo "  [BibTeX]"
	cd $(BUILD_DIR) && $(BIBTEX) $(MAIN_BASE)
	@echo "  [PDF run 2]"
	cd $(SRC_DIR) && $(PDFLATEX) -output-directory ../$(BUILD_DIR) $(MAIN_BASE).tex
	@echo "  [PDF run 3]"
	cd $(SRC_DIR) && $(PDFLATEX) -output-directory ../$(BUILD_DIR) $(MAIN_BASE).tex
	@echo "  ✓ PDF (with BibTeX) generated: $(BUILD_DIR)/$(MAIN_BASE).pdf"

# ── HTML5 Document Compilation (LaTeXML Pipeline) ───────────────────────────
# Converts TeX sources into cross-platform accessible web files.
html: figures | $(BUILD_DIR)/
	@echo "  [LaTeXML]   $(MAIN_BASE).tex"
	@# Copy user stylesheet into the build directory
	cp $(SCRIPTS_DIR)/custom.css $(BUILD_DIR)/custom.css
	
	@# Stage 1: Parse LaTeX into semantically structured XML.
	@# The babel bypass option is active to prevent standard package runtime crashes.
	$(LATEXML) \
		--dest=$(BUILD_DIR)/$(MAIN_BASE).xml \
		$(SRC_DIR)/$(MAIN_BASE).tex
		
	@# Stage 2: Transform XML to validated HTML5 markup.
	@# Injects custom styles and loads the CDN-backed MathJax processor for equations.
	@# Note: --css takes a path relative to the final HTML file location.
	$(LATEXMLPOST) \
		--format=html5 \
		--css=$(BUILD_DIR)/custom.css \
		--javascript="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js" \
		--dest=$(BUILD_DIR)/$(MAIN_BASE).html \
		$(BUILD_DIR)/$(MAIN_BASE).xml
		
	@echo "  ✓ HTML generated: $(BUILD_DIR)/$(MAIN_BASE).html"

# ── Continuous Automation ────────────────────────────────────────────────────
# Development loop using 'entr'. Automatically rebuilds assets on source changes.
watch:
	@echo "  Watching $(SRC_DIR)/ and $(FIG_TIKZ)/ — Press Ctrl+C to stop"
	find $(SRC_DIR) $(FIG_TIKZ) -name '*.tex' | entr -c make all

# ── Cleanup Operations ───────────────────────────────────────────────────────
# Deletes individual standalone graphics build directories.
figures-clean:
	@echo "  [clean]     Sub-directory $(FIG_BUILD)/"
	rm -rf $(FIG_BUILD)

# Deletes document compilation output.
clean:
	@echo "  [clean]     Sub-directory $(BUILD_DIR)/"
	rm -rf $(BUILD_DIR)

# Radical cleanup removing all compiled targets and miscellaneous TeX log artifacts.
distclean: clean figures-clean
	@echo "  [clean]     Residual LaTeX workspace artifacts"
	rm -f $(SRC_DIR)/*.aux $(SRC_DIR)/*.log $(SRC_DIR)/*.toc \
	      $(SRC_DIR)/*.out $(SRC_DIR)/*.lof $(SRC_DIR)/*.lot \
	      $(SRC_DIR)/*.xml $(SRC_DIR)/*.html $(SRC_DIR)/*.css

# ── Documented Interface Helper ──────────────────────────────────────────────
# Prints explicit usage hints when executing plain 'make help'.
help:
	@echo ""
	@echo "  LaTeX Dual-Output Workflow (LaTeXML Edition)"
	@echo "  ─────────────────────────────────────────────"
	@echo "  make                Compiles assets, print PDF, and accessible HTML5"
	@echo "  make figures        Compiles standalone TikZ assets only (PDF + SVG)"
	@echo "  make pdf            Generates print document natively (2 LaTeX passes)"
	@echo "  make pdf-full       Generates print document with active BibTeX citations"
	@echo "  make html           Generates web asset targets only (via LaTeXML parsing)"
	@echo "  make watch          Monitors workspace files and live-rebuilds via 'entr'"
	@echo "  make clean          Purges the main document build directory ($(BUILD_DIR)/)"
	@echo "  make figures-clean  Purges the vector graphics build directory ($(FIG_BUILD)/)"
	@echo "  make distclean      Complete workspace wipe including localized cached files"
	@echo ""