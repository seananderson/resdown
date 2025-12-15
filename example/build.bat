@echo off
REM Build script for dossier - Windows version
REM Converts Makefile functionality to Windows batch

setlocal enabledelayedexpansion

REM Define input and output files
set INPUT_ORIG=01-frontmatter.md 02-main.md
set INPUT_OTHER=03-annex-A-relevant.md 04-annex-B-innovation.md 05-annex-C-impact.md 06-annex-D-recognition.md 07-annex-E1-productivity-RDA.md 08-annex-E2-productivity-MR.md 09-annex-E3-productivity-RCS.md

set OUTPUT_PDF=dossier.pdf
set OUTPUT_DOCX=dossier.docx

REM Check command line argument
if "%1"=="clean" goto :clean
if "%1"=="docx" goto :build_docx
if "%1"=="continuous" goto :continuous
if "%1"=="" goto :build_pdf
if "%1"=="pdf" goto :build_pdf

echo Unknown target: %1
echo Usage: build.bat [pdf^|docx^|clean^|continuous]
exit /b 1

:build_pdf
echo Building PDF...

REM Step 1: Generate word count substituted files
call word_count_substitute.bat 01-frontmatter.md
if errorlevel 1 exit /b 1
call word_count_substitute.bat 02-main.md
if errorlevel 1 exit /b 1

REM Step 2: Generate context sum files
call context_sum_substitute.bat 01-frontmatter-sub.md
if errorlevel 1 exit /b 1
del /f 01-frontmatter-sub.md

call context_sum_substitute.bat 02-main-sub.md
if errorlevel 1 exit /b 1
del /f 02-main-sub.md

REM Step 3: Generate value-substituted context sum files
call value_substitute.bat 01-frontmatter-sub-contextsums.md
if errorlevel 1 exit /b 1
call value_substitute.bat 02-main-sub-contextsums.md
if errorlevel 1 exit /b 1

REM Step 4: Generate value-substituted files for INPUT_OTHER
for %%f in (%INPUT_OTHER%) do (
    call value_substitute.bat %%f
    if errorlevel 1 exit /b 1
)

REM Step 5: Concatenate all files
(
    type 01-frontmatter-sub-contextsums-valuesub.md
    type 02-main-sub-contextsums-valuesub.md
    type 03-annex-A-relevant-valuesub.md
    type 04-annex-B-innovation-valuesub.md
    type 05-annex-C-impact-valuesub.md
    type 06-annex-D-recognition-valuesub.md
    type 07-annex-E1-productivity-RDA-valuesub.md
    type 08-annex-E2-productivity-MR-valuesub.md
    type 09-annex-E3-productivity-RCS-valuesub.md
) > dossier.md

REM Step 6: Render PDF with R
Rscript -e "resdown::render_dossier(output = 'dossier-temp.pdf', cleanup = FALSE)"
if errorlevel 1 exit /b 1

REM Step 7: Combine with preamble
pdftk preamble.pdf dossier-temp.pdf cat output dossier.pdf
if errorlevel 1 exit /b 1

REM Step 8: Cleanup
del /f dossier-temp.*
del /f dossier.md
del /f 01-frontmatter-sub-contextsums.md 02-main-sub-contextsums.md
del /f 01-frontmatter-sub-contextsums-valuesub.md 02-main-sub-contextsums-valuesub.md
del /f 03-annex-A-relevant-valuesub.md 04-annex-B-innovation-valuesub.md 05-annex-C-impact-valuesub.md 06-annex-D-recognition-valuesub.md 07-annex-E1-productivity-RDA-valuesub.md 08-annex-E2-productivity-MR-valuesub.md 09-annex-E3-productivity-RCS-valuesub.md

echo PDF build complete: %OUTPUT_PDF%
goto :end

:build_docx
echo Building DOCX...

REM Step 1: Generate word count substituted files
call word_count_substitute.bat 01-frontmatter.md
if errorlevel 1 exit /b 1
call word_count_substitute.bat 02-main.md
if errorlevel 1 exit /b 1

REM Step 2: Generate context sum files
call context_sum_substitute.bat 01-frontmatter-sub.md
if errorlevel 1 exit /b 1
del /f 01-frontmatter-sub.md

call context_sum_substitute.bat 02-main-sub.md
if errorlevel 1 exit /b 1
del /f 02-main-sub.md

REM Step 3: Generate value-substituted context sum files
call value_substitute.bat 01-frontmatter-sub-contextsums.md
if errorlevel 1 exit /b 1
call value_substitute.bat 02-main-sub-contextsums.md
if errorlevel 1 exit /b 1

REM Step 4: Generate value-substituted files for INPUT_OTHER
for %%f in (%INPUT_OTHER%) do (
    call value_substitute.bat %%f
    if errorlevel 1 exit /b 1
)

REM Step 5: Concatenate all files
(
    type 01-frontmatter-sub-contextsums-valuesub.md
    type 02-main-sub-contextsums-valuesub.md
    type 03-annex-A-relevant-valuesub.md
    type 04-annex-B-innovation-valuesub.md
    type 05-annex-C-impact-valuesub.md
    type 06-annex-D-recognition-valuesub.md
    type 07-annex-E1-productivity-RDA-valuesub.md
    type 08-annex-E2-productivity-MR-valuesub.md
    type 09-annex-E3-productivity-RCS-valuesub.md
) > dossier.md

REM Step 6: Render DOCX with R
Rscript -e "resdown::render_dossier(output = 'dossier.docx', cleanup = FALSE)"
if errorlevel 1 exit /b 1

REM Step 7: Cleanup
del /f dossier.md
del /f 01-frontmatter-sub-contextsums.md 02-main-sub-contextsums.md
del /f 01-frontmatter-sub-contextsums-valuesub.md 02-main-sub-contextsums-valuesub.md
del /f 03-annex-A-relevant-valuesub.md 04-annex-B-innovation-valuesub.md 05-annex-C-impact-valuesub.md 06-annex-D-recognition-valuesub.md 07-annex-E1-productivity-RDA-valuesub.md 08-annex-E2-productivity-MR-valuesub.md 09-annex-E3-productivity-RCS-valuesub.md

echo DOCX build complete: %OUTPUT_DOCX%
goto :end

:clean
echo Cleaning build artifacts...
del /f %OUTPUT_PDF% %OUTPUT_DOCX% 2>nul
del /f 01-frontmatter-sub.md 02-main-sub.md 2>nul
del /f 01-frontmatter-sub-contextsums.md 02-main-sub-contextsums.md 2>nul
del /f 01-frontmatter-sub-contextsums-valuesub.md 02-main-sub-contextsums-valuesub.md 2>nul
del /f 03-annex-A-relevant-valuesub.md 04-annex-B-innovation-valuesub.md 05-annex-C-impact-valuesub.md 06-annex-D-recognition-valuesub.md 07-annex-E1-productivity-RDA-valuesub.md 08-annex-E2-productivity-MR-valuesub.md 09-annex-E3-productivity-RCS-valuesub.md 2>nul
del /f dossier.md dossier.aux dossier.log dossier.out dossier.toc dossier.tex 2>nul
echo Clean complete.
goto :end

:continuous
echo Starting continuous build mode (Ctrl+C to stop)...
:continuous_loop
call :build_pdf
timeout /t 2 /nobreak >nul
goto :continuous_loop

:end
endlocal
