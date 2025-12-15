@echo off
setlocal enabledelayedexpansion

REM value_substitute.bat - Substitute values from values.txt into markdown files
REM Usage: value_substitute.bat input.md
REM
REM Reads tag-value pairs from values.txt (format: "tag, value")
REM Replaces all $tag$ occurrences in the input file with their values
REM Outputs to input-valuesub.md (preserves original)
REM Tags not found in values.txt are replaced with "MISSING"

if "%~1"=="" (
    echo Usage: %~nx0 input_file.md
    exit /b 1
)

set "input_file=%~1"
set "base=%input_file:.md=%"
set "output_file=%base%-valuesub.md"
set "values_file=values.txt"

REM Check if input file exists
if not exist "%input_file%" (
    echo Error: Input file '%input_file%' not found
    exit /b 1
)

REM Check if values file exists
if not exist "%values_file%" (
    echo Error: Values file '%values_file%' not found
    exit /b 1
)

REM Copy input to output
copy "%input_file%" "%output_file%" >nul

REM Find all unique tags in the input file ($tag$ format)
set "tags_file=%TEMP%\tags_%RANDOM%.tmp"
set "unique_tags=%TEMP%\unique_tags_%RANDOM%.tmp"

REM Extract all $..$ patterns
type "%input_file%" | findstr /r "\$[^$]*\$" > "%tags_file%" 2>nul

REM Parse tags from the file (this is complex in batch, so we'll process line by line)
if exist "%unique_tags%" del "%unique_tags%"

REM Process each tag found in input
for /f "delims=" %%a in ('type "%input_file%"') do (
    set "line=%%a"
    call :extract_and_substitute "!line!"
)

del "%tags_file%" 2>nul
del "%unique_tags%" 2>nul

echo Created %output_file% with substituted values
goto :eof

:extract_and_substitute
set "line=%~1"
set "remaining=%line%"

:loop
REM Find the position of the first $
set "before="
set "after="

for /f "tokens=1* delims=$" %%a in ("!remaining!") do (
    set "before=%%a"
    set "after=%%b"
)

if not defined after goto :eof

REM Now extract the tag (everything before the next $)
for /f "tokens=1* delims=$" %%a in ("!after!") do (
    set "tag=%%a"
    set "remaining=%%b"

    REM Look for this tag in values.txt
    set "value="
    for /f "tokens=1* delims=," %%c in ('findstr /b /c:"!tag!," "%values_file%" 2^>nul') do (
        set "value=%%d"
        REM Trim leading/trailing spaces
        for /f "tokens=* delims= " %%e in ("!value!") do set "value=%%e"
    )

    if defined value (
        REM Tag exists - substitute the value in the output file
        call :replace_in_file "$!tag!$" "!value!"
    ) else (
        REM Tag not found - mark as MISSING
        echo Warning: Tag '!tag!' not found in %values_file%, substituting with 'MISSING'
        call :replace_in_file "$!tag!$" "MISSING"
    )
)

goto loop

:replace_in_file
set "search=%~1"
set "replace=%~2"

REM Escape special characters for replacement
set "search_esc=%search%"
set "replace_esc=%replace%"

REM PowerShell is more reliable for this complex substitution
powershell -NoProfile -Command "(Get-Content '%output_file%') -replace [regex]::Escape('%search%'), '%replace_esc%' | Set-Content '%output_file%'"

goto :eof
