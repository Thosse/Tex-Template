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
├── .build/             ← Temporary hidden build artifacts and logs
├── bin/                ← Wrapper scripts (build.sh, detect_engine.sh, run.sh)
├── defaults/           ← Shared configurations and web assets
│   ├── custom.css      ← CSS styling for HTML output
│   ├── mathjax.js      ← MathJax configuration for equations
│   └── preamble.tex    ← Dual-build gatekeeper and package imports
├── result/             ← Final compiled outputs
│   ├── html/           ← Final compiled PDF output
│   └── main.pdf        ← Final compiled PDF output
├── src/                ← Source files
│   ├── figures/        ← Standalone TikZ figures and build output
│   └── main.tex        ← Main LaTeX source document
├── .gitignore          ← Git exclusion rules
├── Dockerfile          ← Container build definition
├── Makefile            ← Defines the dual-output automation
└── README.md           ← Project documentation
```


## How It Works

### Dual-Output Detection

LaTeXML struggles with complex LaTeX3 (expl3) macros or specific print layouts-
Thus the workflow uses a robust \newif gatekeeper defined in defaults/preamble.tex.
This safely routes package loading
without causing compilation crashes in either environment:

You can conditionally load problematic parts in the preamble or in the body with

```latex
\iflatexml  % HTML BUILD (LaTeXML)
    % Provide lightweight dummy macros here if needed
\else       % PDF BUILD (pdflatex)
    % This only applies to PDF Builds
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
