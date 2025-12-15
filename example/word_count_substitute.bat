@echo off
setlocal enabledelayedexpansion

REM Script to count words between <!--start count--> and <!--end count--> tags
REM and substitute XX with the word count on the line two lines above the start tag

if "%~1"=="" (
    echo Usage: %~nx0 ^<file1.md^> [file2.md] ...
    echo        %~nx0 *.md  # Process all .md files
    exit /b 1
)

:process_all_files
if "%~1"=="" goto end

set "input_file=%~1"

REM Check if file exists and has .md extension
if not exist "%input_file%" (
    echo Skipping: %input_file% ^(doesn't exist^)
    shift
    goto process_all_files
)

echo %input_file% | findstr /i "\.md$" >nul
if errorlevel 1 (
    echo Skipping: %input_file% ^(not a .md file^)
    shift
    goto process_all_files
)

REM Generate output filename
set "output_file=%input_file:.md=-sub.md%"

echo Processing: %input_file% -^> %output_file%

REM Create a temporary file
set "temp_file=%TEMP%\word_count_%RANDOM%.tmp"
copy "%input_file%" "%temp_file%" >nul

REM Find all start tags and process them
set line_num=0
for /f "delims=" %%a in ('type "%input_file%"') do (
    set /a line_num+=1
    echo %%a | findstr /c:"<!--start count-->" >nul
    if not errorlevel 1 (
        call :process_tag !line_num! "%input_file%" "%temp_file%"
    )
)

REM Copy processed file to output
copy "%temp_file%" "%output_file%" >nul
del "%temp_file%"

echo Created: %output_file%

shift
goto process_all_files

:process_tag
set start_line=%1
set input_file=%~2
set temp_file=%~3

echo Found start tag at line %start_line%

REM Find the corresponding end tag
set /a search_from=%start_line% + 1
set end_line=0
set current_line=0

for /f "delims=" %%a in ('type "%input_file%"') do (
    set /a current_line+=1
    if !current_line! geq %search_from% (
        echo %%a | findstr /c:"<!--end count-->" >nul
        if not errorlevel 1 (
            if !end_line! equ 0 (
                set end_line=!current_line!
            )
        )
    )
)

if !end_line! equ 0 (
    echo Warning: No matching end tag found for start tag at line %start_line%
    goto :eof
)

echo Found end tag at line !end_line!

REM Extract content between tags and count words
set /a start_extract=%start_line% + 1
set /a end_extract=!end_line! - 1

set "content_file=%TEMP%\content_%RANDOM%.tmp"
set extract_line=0

(for /f "delims=" %%a in ('type "%input_file%"') do (
    set /a extract_line+=1
    if !extract_line! geq %start_extract% if !extract_line! leq %end_extract% echo %%a
)) > "%content_file%"

REM Count words in content
set word_count=0
for /f %%w in ('type "%content_file%"') do (
    set /a word_count+=1
)

del "%content_file%"

echo Word count: !word_count!

REM Find the line two lines above the start tag
set /a target_line=%start_line% - 2

if !target_line! lss 1 (
    echo Warning: Target line !target_line! is invalid ^(less than 1^)
    goto :eof
)

REM Check if XX exists on the target line and replace it
set check_line=0
set found_xx=0

(for /f "delims=" %%a in ('type "%temp_file%"') do (
    set /a check_line+=1
    if !check_line! equ !target_line! (
        echo %%a | findstr /c:"XX" >nul
        if not errorlevel 1 (
            set found_xx=1
            set "line=%%a"
            set "line=!line:XX=%word_count%!"
            echo !line!
        ) else (
            echo ERROR: No 'XX' found on line !target_line! ^(2 lines above start tag at line %start_line%^)
            echo        Line !target_line! contains: '%%a'
            echo        Did you forget to remove blank lines between the header and ^<!--start count--^>?
            del "%temp_file%"
            exit /b 1
        )
    ) else (
        echo %%a
    )
)) > "%temp_file%.new"

if !found_xx! equ 1 (
    move /y "%temp_file%.new" "%temp_file%" >nul
    echo Replacing XX on line !target_line! with !word_count!
) else (
    del "%temp_file%.new"
)

goto :eof

:end
echo Processing complete!
endlocal
