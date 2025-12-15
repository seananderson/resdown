@echo off
setlocal enabledelayedexpansion

REM Script to sum subsection word counts within each CONTEXT section
REM and substitute XX with the total in each CONTEXT header

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
set "output_file=%input_file:.md=-contextsums.md%"

echo Processing: %input_file% -^> %output_file%

REM Create a temporary file
set "temp_file=%TEMP%\context_sum_%RANDOM%.tmp"
copy "%input_file%" "%temp_file%" >nul

REM Count total lines in file
set total_lines=0
for /f %%a in ('type "%input_file%" ^| find /c /v ""') do set total_lines=%%a

REM Find all CONTEXT section headers
set context_count=0
for /f "tokens=1* delims=:" %%a in ('findstr /n /r "^# CONTEXT:" "%input_file%"') do (
    set /a context_count+=1
    set context_line_!context_count!=%%a
)

REM Process each CONTEXT section
for /l %%i in (1,1,%context_count%) do (
    set context_line=!context_line_%%i!
    echo Found CONTEXT section at line !context_line!

    REM Determine the end of this CONTEXT section
    set /a next_index=%%i + 1
    if !next_index! leq %context_count% (
        set next_context_line=!context_line_!next_index!!
    ) else (
        set /a next_context_line=%total_lines% + 1
    )

    set /a section_end=!next_context_line! - 1
    echo CONTEXT section spans lines !context_line! to !section_end!

    REM Extract section and find word counts
    set total=0
    set current_line=0

    for /f "delims=" %%a in ('type "%input_file%"') do (
        set /a current_line+=1
        if !current_line! geq !context_line! if !current_line! leq !section_end! (
            REM Check if line matches pattern "## ... (NNN words)"
            echo %%a | findstr /r /c:"^## .* ([0-9][0-9]* words)" >nul
            if not errorlevel 1 (
                REM Extract the number from the line
                for /f "tokens=*" %%b in ("%%a") do (
                    set "line=%%b"
                    REM Extract number between parentheses
                    for /f "tokens=2 delims=()" %%c in ("!line!") do (
                        for /f "tokens=1" %%d in ("%%c") do (
                            set /a total+=%%d
                        )
                    )
                )
            )
        )
    )

    echo Total word count for this CONTEXT: !total!

    REM Replace XX in the CONTEXT header with the total
    if !total! gtr 0 (
        echo Replacing XX on line !context_line! with !total!
        set replace_line=0
        (for /f "delims=" %%a in ('type "%temp_file%"') do (
            set /a replace_line+=1
            if !replace_line! equ !context_line! (
                set "line=%%a"
                set "line=!line:XX=%total%!"
                echo !line!
            ) else (
                echo %%a
            )
        )) > "%temp_file%.new"
        move /y "%temp_file%.new" "%temp_file%" >nul
    ) else (
        echo No word counts found in this section, skipping replacement
    )
)

REM Copy processed file to output
copy "%temp_file%" "%output_file%" >nul
del "%temp_file%"

echo Created: %output_file%

shift
goto process_all_files

:end
echo Processing complete!
endlocal
