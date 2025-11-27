process_cross_refs <- function(input = "dossier.md", output = "processed.md", type = c("docx", "pdf", "tex", "html")) {
  x <- readLines(input)

  type <- match.arg(type)
  pdf <- type == "pdf"

  # steps:
  # iterate through lists and replace {subsec} with incremented numbers
  # iterate through lists and replace {subsec-letter} with incremented letters
  #
  # now iterate through each subsection and increment the references by
  # adding `-1` `-2` etc.
  # record the original label and the parsed label
  # a subsection is now defined as `"## [A-Z][0-9][a-z]?\\. "`
  # if there's no subsection, pretend all subsection 1
  #
  # put file back together
  #
  # do the regex sub on the whole file

  labs <- list()
  ii <- 1

  section_lines <- grep("^# List [A-Z]", x)

  for (i in seq_along(section_lines)) {
    from1 <- section_lines[i]
    to1 <- if (i == length(section_lines)) length(x) else section_lines[i + 1] - 1
    s <- x[from1:to1]

    subsection_lines <- grep("^## [A-Z]\\{subsec\\}\\.", s)
    subsection_lines2 <- grep("^## [A-Z][0-9]\\{subsec-letter\\}\\.", s)
    subsection_lines <- sort(union(subsection_lines, subsection_lines2))
    for (j in seq_along(subsection_lines)) {
      from2 <- subsection_lines[j]
      to2 <- if (j == length(subsection_lines)) length(s) else subsection_lines[j + 1] - 1
      ss <- s[from2:to2]

      this_letter <- str_extract(ss[1], "[A-Z](?=\\{)")
      ss[1] <- gsub("\\{subsec\\}", j, ss[1])
      ss[1] <- gsub("\\{subsec-letter\\}", letters[j], ss[1])

      # if (pdf) {
      #   ss[1] <- c(
      #     paste0(ss[1], " ",
      #       "\n \\begin{enumerate}[label = ", this_letter, "\\arabic*]")
      #   )
      #   ss[length(ss)] <- c(
      #     paste0(ss[length(ss)], " ", "\\end{enumerate}")
      #   )
      # }

      s[from2:to2] <- ss
    }
    x[from1:to1] <- s
  }

  # if (pdf) {
  #   m <- grep("^## E1[a-z]", x)
  #   for (i in seq(1, length(m) - 1)) {
  #     chunk <- x[m[i]:(m[i+1]-1)]
  #     if (any(grepl("@", chunk))) { # contains any bullets with labels
  #       this_label <- str_extract(chunk[1], "(?<=^## )E1[a-z](?=\\.)")
  #       chunk[1] <- c(
  #         paste0(chunk[1], " ",
  #           "\n \\begin{enumerate}[label = ", this_letter, "\\arabic*]")
  #       )
  #       chunk[length(chunk)] <- c(
  #         paste0(chunk[length(chunk)], " ", "\\end{enumerate}")
  #       )
  #       x[m[i]:(m[i+1]-1)] <- chunk
  #     }
  #   }
  # }

  subsection_lines <- grep("## [A-Z][0-9][a-z]?\\.", x)

  # relevant factors doesn't have subsections
  listA <- grep("^# List A: RELEVANT FACTORS$", x)
  listB <- grep("^# List B", x)

  # if (pdf) {
  #   chunk <- x[listA:(listB - 1)]
  #   if (any(grepl("@", chunk))) { # contains any bullets with labels
  #     this_label <- "A1"
  #     chunk[1] <- c(
  #       paste0(chunk[1], " ",
  #         "\n \\begin{enumerate}[label = ", this_letter, "\\arabic*]")
  #     )
  #     chunk[length(chunk)] <- c(
  #       paste0(chunk[length(chunk)], " ", "\\end{enumerate}")
  #     )
  #     x[listA:(listB - 1)] <- chunk
  #   }
  # }

  subsection_lines <- sort(union(listA, subsection_lines))

  for (i in seq_along(subsection_lines)) {
    from2 <- subsection_lines[i]
    to2 <- if (i == length(subsection_lines)) length(x) else subsection_lines[i + 1] - 1
    ss <- x[from2:to2]

    if (i == 1) { # relevant factors list, no subsections
      label_prefix <- "A1"
    } else {
      label_prefix <- str_extract(ss[1], "(?<=## )[A-Z][0-9][a-z]*")
    }

    # alternate:
    # re <- "^(\\*{1,2})?\\(ref:[a-zA-Z0-9]+\\)"
    # print(label_prefix)
    # re <- "^(\\*{1,2})?\\@[a-zA-Z0-9_\\-]+"
    # re2 <- "^((\\*{1,2})?)\\@([a-zA-Z0-9_\\-]+)" # same but don't replace the * or **

    re <- "^(\\\\\\*\\\\\\*|\\\\\\*)?\\@[a-zA-Z0-9_\\-]+"
    re2 <- "^(\\\\\\*\\\\\\*|\\\\\\*)?)\\@([a-zA-Z0-9_\\-]+)" # same but don't replace the * or **

    refs_lines <- grep(re, ss)
    refs <- str_extract(ss[refs_lines], re)
    # refs <- sub("^\\*{1,2}", "", refs)
    refs <- sub("^\\\\\\*\\\\\\*|\\\\\\*", "", refs)

    for (k in seq_along(refs_lines)) {
      label <- paste0(label_prefix, "-", k)
      labs[[ii]] <- data.frame(ref = refs[k], label = label)
      ss[refs_lines[k]] <- gsub(re2, paste0("\\1", label), ss[refs_lines[k]])
      ii <- ii + 1
    }

    if (pdf) {
      ss[refs_lines] <- paste("\\item", ss[refs_lines])
    }
    x[from2:to2] <- ss
  }

  labs_df <- do.call(rbind, labs)

  labs_df$tex_label <- paste0("\\label{itm:", gsub("@", "", labs_df$ref), "}")
  labs_df$tex_ref <- paste0("\\ref{itm:", gsub("@", "", labs_df$ref), "}")

  # now iterate through and sub in refs

  if (!type %in% c("pdf", "tex")) {
    for (i in seq_len(nrow(labs_df))) {
      x <- str_replace_all(x, labs_df$ref[i], labs_df$label[i])
    }
  # } else {
    # if starts with... label, otherwise ref
    # needs_label <- stringr::str_detect(x, re)
    # x[needs_label]

    # for (i in seq_len(nrow(labs_df))) {
      # new_regex <- paste0("^(\\\\\\*\\\\\\*|\\\\\\*)?\\", labs_df$ref)
      # x <- stringr::str_replace(x, new_regex, labs_df$label[i])
    # }

  ats_remaining <- grep("@[a-zA-Z0-9_\\-]+", x)
  if (length(ats_remaining)) {
    cli::cli_abort("Some references not matched: {x[ats_remaining]}")
  }
  }

  writeLines(x, output)
}

process_cross_refs_tex <- function(input = "dossier.md", output = "processed.md") {

}

render_processed_dossier <- function(
    input = "processed.md",
  output = c("dossier.docx", "dossier.pdf", "dossier.html", "dossier.tex"),
  cleanup = TRUE) {
  out <- strsplit(output, "\\.")

  xx <- lapply(out, \(o) {
    ofile <- o[1]
    oform <- o[2]

    if (oform == "docx") {
      f <- system.file("template.docx", package = "resdown")
      rmarkdown::render(
        input,
        output_format = rmarkdown::word_document(reference_docx = f),
        output_file = ofile
      )
    } else if (oform == "pdf") {
      # h <- system.file("header.tex", package = "resdown")
      # rmarkdown::render(
      #   input,
      #   output_format = rmarkdown::pdf_document(pandoc_args = c(paste0("--include-in-header=", h))),
      #   output_file = ofile
      # )
      h <- system.file("header.tex", package = "resdown")
      rmarkdown::render(
        input,
        output_format =
          rmarkdown::latex_document(pandoc_args =
              c("--columns=100000",
                paste0("--include-in-header=", h),
                "--variable=indent"
              )),
        output_file = ofile
      )
      f <- paste0(ofile, ".tex")
      fix_tex(f, f)
      system(paste0("latexmk -xelatex ", f))
      # system(paste0("latexmk ", f))
    } else if (oform == "tex") {
      h <- system.file("header.tex", package = "resdown")
      rmarkdown::render(
        input,
        output_format =
          rmarkdown::latex_document(pandoc_args =
              c("--columns=100000",
            paste0("--include-in-header=", h),
            "--variable=indent"
          )),
        output_file = ofile
      )
    } else if (oform == "html") {
      rmarkdown::render(
        input,
        output_format = rmarkdown::html_document(),
        output_file = ofile
      )
    } else {
      cli::cli_abort("Output type not supported")
    }
  })

  if (cleanup) unlink(input)
}

#' Process and render a dossier
#'
#' @param input Input markdown file.
#' @param output A vector of desired outputs.
#' @param cleanup Delete the processed markdown file?
#'
#' @returns One or more rendered dossier files. Defaults to docx and pdf.
#'   Can also do html or a single format.
#' @export
#' @importFrom stringr str_replace_all str_extract
#'
#' @examples
#' \dontrun{
#' file.copy(system.file("dossier.md", package = "resdown"), ".", overwrite = FALSE)
#' render_dossier()
#' }
render_dossier <- function(
    input = "dossier.md",
  output = c("dossier.docx", "dossier.pdf"),
  cleanup = TRUE) {

  out <- strsplit(output, "\\.")

  process_cross_refs(input, output = "processed.md", type = out[[1]][2])
  render_processed_dossier("processed.md", output = output, cleanup = cleanup)
}
