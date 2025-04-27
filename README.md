# resdown

> Research Scientist (*RES*) dossier + Markdown (*down*) 

<!-- badges: start -->
[![R-CMD-check](https://github.com/seananderson/resdown/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/seananderson/resdown/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Unofficial Markdown template and R code to produce dossiers for Fisheries and
Oceans Canada Research Scientists under the Career Progression Management
Framework.

The dossier format includes considerable cross referencing of "Annex" evidence
in a custom format. The markdown file `dossier.md` is processed by the function
`render_dossier()` to number or letter subsections, generate the cross
references, and render the document into a `.docx` file that can be copied into
the official template with (hopefully) minimal modifications. A `.html` and
`.pdf` version can also be generated for faster iteration while writing.

## Installation

```r
# install.packages("pak")
pak::pkg_install("seananderson/resdown")
```

## Example

Copy the Markdown template:

```r
file.copy(system.file("dossier.md", package = "resdown"), ".")
```

Then edit `dossier.md` as desired.

Render the dossier:

```r
resdown::render_dossier()
```

```r
list.files(pattern = "dossier\\.")
#> [1] "dossier.docx" "dossier.md"   "dossier.pdf" 
```

Copy the contents of `dossier.docx` into the official `.docx` template.
