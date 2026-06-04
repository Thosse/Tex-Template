# LaTeX Dual-Output Workflow — Beispielprojekt

Aus **einer einzigen `.tex`-Datei** werden sowohl ein **PDF** als auch
eine **HTML-Seite** erzeugt.

## Voraussetzungen

| Werkzeug | Paket (Ubuntu/Debian) | Zweck |
|---|---|---|
| `pdflatex` | `texlive-latex-base` | PDF-Erzeugung |
| `make4ht` | `tex4ht` (in TeX Live) | HTML-Erzeugung |
| `pdf2svg` | `pdf2svg` | TikZ-PDF → SVG |
| `make` | `make` | Build-Steuerung |
| `entr` *(optional)* | `entr` | Auto-Rebuild (`make watch`) |

```bash
# Ubuntu/Debian Schnellinstall:
sudo apt install texlive-full pdf2svg make entr
```

## Projektstruktur

```
latex-workflow/
├── Makefile
├── src/
│   └── main.tex          ← Einzige Quelldatei
├── figures/
│   ├── tikz/             ← TikZ-Quellen (standalone)
│   │   ├── graph.tex
│   │   └── bfs.tex
│   └── build/            ← Erzeugte PDFs + SVGs (git-ignorierbar)
├── build/                ← Ausgabe: main.pdf, main.html, CSS
└── scripts/
    ├── make4ht.cfg       ← make4ht-Konfiguration (Lua)
    └── custom.css        ← CSS für HTML-Ausgabe
```

## Verwendung

```bash
make              # Figuren + PDF + HTML bauen
make figures      # nur TikZ-Figuren neu bauen
make pdf          # nur PDF (2 LaTeX-Läufe)
make html         # nur HTML (make4ht)
make watch        # Auto-Rebuild bei Dateiänderung (entr)
make clean        # build/ löschen
make distclean    # + alle Temp-Dateien löschen
make help         # Übersicht aller Targets
```

## Wie es funktioniert

### Dual-Output-Erkennung

`main.tex` erkennt den Build-Modus über `\ifdefined\HCode`:

```latex
\ifdefined\HCode
  % → make4ht ist aktiv: keine PDF-only-Pakete laden
\else
  % → pdflatex: geometry, fancyhdr, microtype usw. laden
\fi
```

### TikZ-Figuren (Standalone-Ansatz)

Jede Figur ist ein eigenes Dokument mit `\documentclass{standalone}`.
`make` baut daraus erst ein PDF, dann ein SVG:

```
figures/tikz/graph.tex
    → pdflatex → figures/build/graph.pdf
    → pdf2svg  → figures/build/graph.svg
```

Im Hauptdokument wird je nach Modus die richtige Datei eingebunden:

```latex
\ifdefined\HCode
  \includegraphics{../figures/build/graph.svg}
\else
  \includegraphics[width=0.45\textwidth]{../figures/build/graph.pdf}
\fi
```

Make cached: nur geänderte `.tex`-Dateien werden neu gebaut.

### HTML-Styling

`scripts/custom.css` verwendet CSS-Variablen — einfach anpassbar:

```css
:root {
  --color-primary: #2563EB;
  --color-accent:  #7C3AED;
  --max-width:     72ch;
}
```

Dark Mode wird automatisch über `@media (prefers-color-scheme: dark)`
unterstützt.

## Neue TikZ-Figur hinzufügen

1. Datei `figures/tikz/meinefigur.tex` erstellen
   (mit `\documentclass[tikz, border=6pt]{standalone}`)
2. Im Hauptdokument einbinden:
   ```latex
   \ifdefined\HCode
     \includegraphics{../figures/build/meinefigur.svg}
   \else
     \includegraphics[width=0.6\textwidth]{../figures/build/meinefigur.pdf}
   \fi
   ```
3. `make figures` oder einfach `make` ausführen —
   Make erkennt die neue Datei automatisch über das Wildcard-Muster.
