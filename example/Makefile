INPUT_ORIG = 01-frontmatter.md 02-main.md
INPUT_SUB = 01-frontmatter-sub.md 02-main-sub.md
INPUT_CONTEXTSUMS = 01-frontmatter-sub-contextsums.md 02-main-sub-contextsums.md
INPUT_CONTEXTSUMS_VALUESUB = 01-frontmatter-sub-contextsums-valuesub.md 02-main-sub-contextsums-valuesub.md
INPUT_OTHER = 03-annex-A-relevant.md 04-annex-B-innovation.md 05-annex-C-impact.md 06-annex-D-recognition.md 07-annex-E1-productivity-RDA.md 08-annex-E2-productivity-MR.md 09-annex-E3-productivity-RCS.md
INPUT_OTHER_VALUESUB = 03-annex-A-relevant-valuesub.md 04-annex-B-innovation-valuesub.md 05-annex-C-impact-valuesub.md 06-annex-D-recognition-valuesub.md 07-annex-E1-productivity-RDA-valuesub.md 08-annex-E2-productivity-MR-valuesub.md 09-annex-E3-productivity-RCS-valuesub.md
INPUT_ALL = $(INPUT_CONTEXTSUMS_VALUESUB) $(INPUT_OTHER_VALUESUB)
OUTPUT_PDF = dossier.pdf
OUTPUT_DOCX = dossier.docx

all: $(OUTPUT_PDF)

# Generate word count substituted files
01-frontmatter-sub.md: 01-frontmatter.md word_count_substitute.sh
	./word_count_substitute.sh 01-frontmatter.md

02-main-sub.md: 02-main.md word_count_substitute.sh
	./word_count_substitute.sh 02-main.md

# Generate context sum files (depends on -sub files)
01-frontmatter-sub-contextsums.md: 01-frontmatter-sub.md context_sum_substitute.sh
	./context_sum_substitute.sh 01-frontmatter-sub.md
	rm -f 01-frontmatter-sub.md

02-main-sub-contextsums.md: 02-main-sub.md context_sum_substitute.sh
	./context_sum_substitute.sh 02-main-sub.md
	rm -f 02-main-sub.md

# Generate value-substituted context sum files (depends on -contextsums files)
%-sub-contextsums-valuesub.md: %-sub-contextsums.md value_substitute.sh values.txt
	./value_substitute.sh $<

# Generate value-substituted files for INPUT_OTHER
%-valuesub.md: %.md value_substitute.sh values.txt
	./value_substitute.sh $<

$(OUTPUT_PDF): $(INPUT_ALL) publication_table.tex preamble.pdf
	# sed -i '' 's/DrA/Dr. Anderson/g' $(INPUT_ALL)
	cat $(INPUT_ALL) > dossier.md
	Rscript -e 'resdown::render_dossier(output = "dossier-temp.pdf", cleanup = FALSE)'
	pdftk preamble.pdf dossier-temp.pdf cat output dossier.pdf
	rm -f dossier-temp.*
	rm dossier.md
	rm -f $(INPUT_CONTEXTSUMS) $(INPUT_CONTEXTSUMS_VALUESUB) $(INPUT_OTHER_VALUESUB)

$(OUTPUT_DOCX): $(INPUT_ALL)
	cat $(INPUT_ALL) > dossier.md
	Rscript -e 'resdown::render_dossier(output = "dossier.docx", cleanup = FALSE)'
	rm dossier.md
	rm -f $(INPUT_CONTEXTSUMS) $(INPUT_CONTEXTSUMS_VALUESUB) $(INPUT_OTHER_VALUESUB)

clean:
	rm -f $(OUTPUT_PDF) $(OUTPUT_DOCX) $(INPUT_SUB) $(INPUT_CONTEXTSUMS) $(INPUT_CONTEXTSUMS_VALUESUB) $(INPUT_OTHER_VALUESUB) dossier.md
	rm -f dossier.aux dossier.log dossier.out dossier.toc dossier.tex

continuous:
	while true; do \
		$(MAKE) $(OUTPUT_PDF); \
		sleep 2; \
	done
