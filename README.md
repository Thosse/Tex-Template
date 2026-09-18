# LaTeX Dual-Output Workflow

This project generates both a high-quality **PDF**
and a modern, responsive **HTML5** document
from a single unified LaTeX source file.


## Build Environments

### Containerized Build (Docker / Podman)

This is the recommended approach.
It guarantees a reproducible environment without a massive TeX installation.
The included scripts automatically detect and prioritize Podman over Docker,
mapping your local user IDs to prevent permission conflicts.
It requires Podman or Docker installed on your system.

Build the container image via

```bash
./bin/build.sh
```

Instead of calling make directly, you may pass any make commands to the run script:

```bash
./bin/run.sh all       # Builds figures, PDF, and HTML
./bin/run.sh pdf       # Builds only the PDF
./bin/run.sh clean     # Cleans the workspace
...
```

### Local Native Build
If you prefer building directly on your host system,
you can use the Makefile natively.

```bash
make              # Builds figures, PDF, and HTML
make figures      # Builds only standalone TikZ figures (PDF + SVG)
make pdf          # Builds only the PDF (multiple LaTeX runs)
make html         # Builds only the HTML (via LaTeXML)
make watch        # Auto-rebuilds on file changes (requires 'entr')
make clean        # Removes all build artifacts and directories
make help         # Shows an overview of all available targets
```

The requirements are listed as in the Dockerfile.


## Project Structure

```
latex-project/
├── bin/                  ← Wrapper scripts (build.sh, run.sh, detect_engine.sh)
├── Makefile              ← Defines the dual-output automation
├── src/
│   └── main.tex          ← Main LaTeX source document
├── figures/
│   ├── tikz/             ← Raw TikZ standalone files (.tex)
│   └── build/            ← Compiled vector graphics (PDF & SVG)
├── build/                ← Temporary build artifacts and logs
├── res/
│   ├── main.pdf          ← Final compiled PDF output
│   └── html/             ← Final compiled HTML5 output
└── scripts/
    ├── custom.css        ← CSS styling for LaTeXML HTML output
    └── mathjax.js        ← MathJax configuration for equations
```


## How It Works

### Dual-Output Detection

`main.tex` can detect the active build mode to load specific packages or adjust formatting.
When using LaTeXML, you can use its native conditional switch:

```latex
\ifdefined\iflatexml
  % → HTML build is active: skip PDF-only packages (like geometry, fancyhdr)
\else
  % → PDF build is active: load print-specific formatting
\fi
```

### TikZ Vector Graphics (Standalone Pipeline)

Each figure is maintained as an independent document in `figures/tikz/` .
The build system processes these assets automatically:

1. Compiles the raw TikZ code into a cropped PDF (`pdflatex`).
2. Converts the generated PDF into an optimized SVG for responsive web views (`pdf2svg`).

Make caches the results; only modified `.tex` files are recompiled.

To include a figure, simply omit the file ending.
The correct file will be used (svg for html and pdf for pdf).

```latex
\includegraphics{../figures/build/graph}
```

### HTML5 Generation (LaTeXML)

The HTML target bypasses standard pdflatex compilation
and instead parses the semantic structure of your .tex source using latexml.
The intermediate XML is then transformed into validated HTML5 via latexmlpost,
injecting custom.css for styling and linking MathJax for equation rendering.
