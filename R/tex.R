fix_tex <- function(input, output) {
  xx <- readLines(input)

  b <- stringr::str_which(xx, "^\\\\begin\\{document")
  x <- xx[b:length(xx)]

  ## extra \\item's !?
  x <- stringr::str_replace_all(
    x,
    "^\\\\item$",
    ""
  )

  x <- stringr::str_replace_all(
    x,
    "^@([A-Za-z0-9_-]+)",
    "\\\\item \\\\label{itm:\\1}"
  )

  x <- stringr::str_replace_all(
    x,
    "^\\*@([A-Za-z0-9_-]+)",
    "\\\\exitem \\\\label{itm:\\1}"
  )

  x <- stringr::str_replace_all(
    x,
    "^\\*\\*@([A-Za-z0-9_-]+)",
    "\\\\initem \\\\label{itm:\\1}"
  )

  x <- stringr::str_replace_all(
    x,
    "@([A-Za-z0-9_-]+[A-Za-z0-9_])", # don't capture - at end for en dashes
    "\\\\ref{itm:\\1}"
  )

  x <- stringr::str_replace_all(x, "-\\\\/-", "--")

  pattern <- "^\\\\subsection\\{([A-Z][0-9]+[a-z]?)"
  .lines <- stringr::str_which(x, pattern)
  labs <- stringr::str_match(x[.lines], pattern)[,2]
  stopifnot(length(.lines) == length(labs))

  pattern <- "^\\\\section\\{List ([A-Z]+)"
  lists <- stringr::str_which(x, pattern)
  list_labs <- stringr::str_match(x[lists], pattern)[,2]

  .lines <- c(lists, .lines)
  labs <- c(list_labs, labs)

  labs <- labs[order(.lines)]
  lines <- .lines[order(.lines)]

  # Track counters for each label prefix to ensure continuity
  label_counters <- list()
  
  for (i in seq(1, length(lines))) {
    from <- lines[i]
    to <- if (i == length(lines)) length(x) - 1 else lines[i + 1] - 1
    chunk <- x[from:to]

    if (any(grepl("\\item|\\exitem|\\initem", chunk))) { # contains any bullets with labels
      this_label <- labs[i]
      
      # Count items in this chunk to update counter
      item_count <- sum(grepl("\\\\item|\\\\exitem|\\\\initem", chunk))
      
      # Get or initialize counter for this label
      if (is.null(label_counters[[this_label]])) {
        label_counters[[this_label]] <- 0
        start_value <- 1
      } else {
        start_value <- label_counters[[this_label]] + 1
      }
      
      # Update counter
      label_counters[[this_label]] <- label_counters[[this_label]] + item_count
      
      chunk[1] <- c(
        paste0(chunk[1], " ",
          # "\n \\begin{enumerate}[label = ", this_label, "-\\arabic*, leftmargin = *]")
          "\n \\begin{enumerate}[label = ", this_label, "-\\arabic*, leftmargin=4.1em,
  labelwidth=3.9em, align=parleft, labelsep=0.2em, start=", start_value, "]") # leftmargin = labelwidth + labelsep
      )
# system("touch ~/src/dossier/dossier.md")

      chunk[length(chunk)] <- c(
        paste0(chunk[length(chunk)], " ", "\\end{enumerate}")
      )
      x[from:to] <- chunk
    }
  }

  out <- c(xx[1:(b-1)], x)
  out

  i <- grep("\\\\hypersetup\\{", out)[2]
  out[i:(i+2)] <- rep("", 3)

  i <- grep("^\\\\documentclass\\[", out)
  out[i] <- "\\documentclass[12pt"

  # bold subsubheaders:
  out <- stringr::str_replace_all(
    out,
    "^\\\\subsubsection\\{",
    "\\\\begin{normalize}"
  )
  out <- stringr::str_replace_all(
    out,
    stringr::regex('^(\\\\begin\\{normalize\\})([a-zA-Z0-9: -]*)\\}(\\\\label\\{[a-zA-Z0-9 :-]*\\})$', multiline = TRUE),
    '\\1 \\\\textbf{\\2} \\\\end{normalize}'
  )
  i <- grep("^\\\\begin\\{normalize", out)
  out[i] <- paste0("\\item[]", out[i])

  # Set paragraph indentation before \begin{document}
  # Only indent paragraphs after the first paragraph following a heading
  i <- grep("^\\\\begin\\{document", out)
  out <- c(out[1:(i-1)],
           "\\setlength{\\parindent}{1.7em}",
           "\\setlength{\\RaggedRightParindent}{1.7em}",
           "\\setlength{\\parskip}{0pt}",
           out[i:length(out)])

  writeLines(out, output)
}
