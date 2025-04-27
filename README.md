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
