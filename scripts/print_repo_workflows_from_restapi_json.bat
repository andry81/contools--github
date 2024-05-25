@echo off

rem USAGE:
rem   print_repo_workflows_from_restapi_json.bat [<Flags>] [--] <JSON_FILE>

rem Description:
rem   Script prints repository workflows from the json file.

rem <Flags>:
rem   --
rem     Stop flags parse.
rem   -skip-sort
rem     Skip repository workflows list alphabetic sort and print as is from the
rem     json file.
rem   -no-path-prefix-remove
rem     Don't remove path prefix (`.github/workflows/`) from the output.
rem   -print-owner-repo-prefix
rem     Print `<owner>/<repo>:` prefix for each workflow.
rem   -filter-inactive
rem     Filter only not "active" workflows.

setlocal DISABLEDELAYEDEXPANSION

call "%%~dp0../__init__/script_init.bat" print . %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

:FREE_TEMP_DIR
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LAST_ERROR%

:MAIN
rem script flags
set FLAG_SKIP_SORT=0
set FLAG_NO_PATH_PREFIX_REMOVE=0
set FLAG_PRINT_OWNER_REPO_PREFIX=0
set FLAG_FILTER_INACTIVE=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-skip-sort" (
    set FLAG_SKIP_SORT=1
  ) else if "%FLAG%" == "-no-path-prefix-remove" (
    set FLAG_NO_PATH_PREFIX_REMOVE=1
  ) else if "%FLAG%" == "-print-owner-repo-prefix" (
    set FLAG_PRINT_OWNER_REPO_PREFIX=1
  ) else if "%FLAG%" == "-filter-inactive" (
    set FLAG_FILTER_INACTIVE=1
  ) else if not "%FLAG%" == "--" (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP
)

set "INOUT_LIST_FILE_TMP0=%SCRIPT_TEMP_CURRENT_DIR%\inout0.lst"
set "INOUT_LIST_FILE_TMP1=%SCRIPT_TEMP_CURRENT_DIR%\inout1.lst"
set "INOUT_LIST_FILE_TMP2=%SCRIPT_TEMP_CURRENT_DIR%\inout2.lst"

set "JSON_FILE=%~1"

if not defined JSON_FILE (
  echo.%?~nx0%: error: JSON_FILE is not defined.
  exit /b 255
) >&2

if not exist "%JSON_FILE%" (
  echo.%?~nx0%: error: JSON_FILE is not found: "%JSON_FILE%".
  exit /b 255
) >&2

rem NOTE:
rem   Docs: https://docs.github.com/en/rest/actions/workflows
rem
if %FLAG_FILTER_INACTIVE% EQU 0 (
  set "JQ_EXPR=.workflows.[].path"
) else set "JQ_EXPR=.workflows.[] | select(.state != \"active\").path"

"%JQ_EXECUTABLE%" -c -r "%JQ_EXPR%" "%JSON_FILE%" > "%INOUT_LIST_FILE_TMP0%" || exit /b

set "INPUT_LIST_FILE=%INOUT_LIST_FILE_TMP0%"

if %FLAG_SKIP_SORT% EQU 0 (
  set "INPUT_LIST_FILE=%INOUT_LIST_FILE_TMP1%"
  sort "%INOUT_LIST_FILE_TMP0%" /O "%INOUT_LIST_FILE_TMP1%"
)

if %FLAG_NO_PATH_PREFIX_REMOVE% NEQ 0 goto NO_PATH_PREFIX_REMOVE

set "FILE_PATH_PREFIX="
if %FLAG_PRINT_OWNER_REPO_PREFIX% NEQ 0 setlocal ENABLEDELAYEDEXPANSION & ^
for /F "eol= tokens=* delims=" %%i in ("!REPO_OWNER!/!REPO!:") do endlocal & set "FILE_PATH_PREFIX=%%i"

set NUM_PRINTED_FILE_PATH=0

(
  for /F "usebackq eol= tokens=* delims=" %%i in ("%INPUT_LIST_FILE%") do set "FILE_PATH=%%i" & call :PROCESS_PATH && set /A NUM_PRINTED_FILE_PATH+=1
) > "%INOUT_LIST_FILE_TMP2%"

type "%INOUT_LIST_FILE_TMP2%"

if %NUM_PRINTED_FILE_PATH% NEQ 0 exit /b 0

exit /b -1

:PROCESS_PATH
setlocal ENABLEDELAYEDEXPANSION
if "!FILE_PATH:~0,18!" == ".github/workflows/" set "FILE_PATH=!FILE_PATH:~18!"
if defined FILE_PATH (
  for /F "eol= tokens=* delims=" %%i in ("!FILE_PATH_PREFIX!!FILE_PATH!") do endlocal & echo.%%i
  exit /b 0
) else endlocal
exit /b -1

:NO_PATH_PREFIX_REMOVE
type "%INPUT_LIST_FILE%"

exit /b 0
