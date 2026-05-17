Thesis Template
===============

A LaTeX template for BSc and MSc style project reports. I updated
and adapted this template while working on my BSc report and am
sharing the result as a starting point for others.

This template is **not affiliated with or endorsed by the University
of Southern Denmark (SDU)**, even though the original version it is
based on came from materials I encountered there. Use it freely and
adapt it to your own institution's requirements.

Here's a couple of relevant LaTeX resources:

- [The TeX FAQ](http://www.texfaq.org/)
- [Lars Madsen's LaTeX book (in Danish)](https://math.medarbejdere.au.dk/latex/bog/)


Compilation instructions
------------------------

To compile the document locally first install LaTeX.

You can now run:
  ```
    pdflatex main
    bibtex main
    pdflatex main
    pdflatex main
  ```

Alternatively you can use `latexmk`:
  ```
    latexmk -pdf main
  ```

Another alternative is to install `make` and simply run it.

You can share your LaTeX source code via git.

Alternatively you can use Overleaf.


Continuous integration
----------------------

The repository includes a GitHub Actions workflow at
[.github/workflows/build-report.yml](.github/workflows/build-report.yml)
that runs on pushes and pull requests targeting `master`, and can also
be triggered manually via `workflow_dispatch`.

For every run the workflow:

- Installs Graphviz, a JRE, and the Chromium runtime libraries needed
  by the Mermaid renderer.
- Caches the PlantUML jar under `scripts/.build/plantuml.jar`.
- Renders Mermaid diagrams via `scripts/render-diagrams.sh` into
  `assets/diagrams/`.
- Compiles `main.tex` with `latexmk -pdf` using
  [xu-cheng/latex-action](https://github.com/xu-cheng/latex-action).
- Uploads the compiled `main.pdf` and the rendered diagram PNGs as
  workflow artifacts (retained for 30 days).

On pushes to `master` the workflow additionally:

- Commits any newly rendered diagrams back to `master` with
  `[skip ci]` to avoid a render loop.
- Bundles the PDF as `bsc-proj-report.pdf` and the diagrams as
  `bsc-proj-report-diagrams.zip`.
- Publishes a GitHub Release tagged `report-YYYY-MM-DD-<shortsha>`
  containing both files, using
  [softprops/action-gh-release](https://github.com/softprops/action-gh-release).

The release-publishing and diagram-commit steps need
`contents: write` permission, which the workflow already declares.
If your fork's default branch is not `master`, update the `on:` and
`if:` clauses accordingly.


Adjustment instructions
-----------------------

To adjust the template:
- Adjust the names, date, and type of thesis on `frontpage.tex`
- Adjust the abstract in `abstract.tex`
- Each chapter resides in a separate file:
  ```
    chap-introduction.tex
    chap-background.tex
    ...
    chap-conclusion.tex
  ```
  These are included from `main.tex`.
  Adjust the chapters and files to your liking.
- The bibliography uses Bibtex. The entries are in `mybibliography.bib`.
  Adjust these to fit your content.
