@echo off

rem USAGE:
rem   print_repo_workflows_from_last_backup_by_config.bat [<Flags>] [--] <CONFIG_FILE>

rem Description:
rem   Script prints all repository workflows from the all latest backed up
rem   RestAPI JSON files using `<CONFIG_FILE>` config file. If `<CONFIG_FILE>`
rem   is a file name, then a file from the output config directory is used.

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
set "BARE_FLAGS="

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
    set BARE_FLAGS=%BARE_FLAGS% %FLAG%
  ) else if "%FLAG%" == "-print-owner-repo-prefix" (
    set FLAG_PRINT_OWNER_REPO_PREFIX=1
    set BARE_FLAGS=%BARE_FLAGS% %FLAG%
  ) else if "%FLAG%" == "-filter-inactive" (
    set FLAG_FILTER_INACTIVE=1
    set BARE_FLAGS=%BARE_FLAGS% %FLAG%
  ) else if not "%FLAG%" == "--" (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP
)

set "INOUT_LIST_FILE_TMP0=%SCRIPT_TEMP_CURRENT_DIR%\inout0.lst"
set "INOUT_LIST_FILE_TMP1=%SCRIPT_TEMP_CURRENT_DIR%\inout1.lst"

set "CONFIG_FILE=%~1"

if not defined CONFIG_FILE (
  echo;%?~%: error: CONFIG_FILE is not defined.
  exit /b 255
) >&2

set "CONFIG_FILE=%CONFIG_FILE:\=/%"

if "%CONFIG_FILE:/=%" == "%CONFIG_FILE%" set "CONFIG_FILE=%CONTOOLS_GITHUB_PROJECT_OUTPUT_CONFIG_ROOT%/%CONFIG_FILE%"

if not exist "%CONFIG_FILE%" (
  echo;%?~%: error: CONFIG_FILE is not found: "%CONFIG_FILE%".
  exit /b 255
) >&2

set "GH_BACKUP_EXTRACT_TEMP_DIR=%SCRIPT_TEMP_CURRENT_DIR%"

set "REDIR_LINE="
if %FLAG_SKIP_SORT% EQU 0 set REDIR_LINE=^>"%INOUT_LIST_FILE_TMP0%"

rem CAUTION:
rem   1. If a variable is empty, then it would not be expanded in the `cmd.exe`
rem      command line or in the inner expression of the
rem      `for /F "usebackq ..." %%i in (`<inner-expression>`) do ...`
rem      statement.
rem   2. The `cmd.exe` command line or the inner expression of the
rem      `for /F "usebackq ..." %%i in (`<inner-expression>`) do ...`
rem      statement does expand twice.
rem
rem   We must expand the command line into a variable to avoid these above.
rem

set "PRINT_BLANK_LINE="
set NUM_PRINTED_JSON_FILES=0

for /F "usebackq eol=# tokens=1,* delims=/" %%i in (%CONFIG_FILE%) do (
  set "REPO_OWNER=%%i"
  set "REPO=%%j"

  call set "GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE_PTTN=%%GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE_NAME:{{OWNER}}=%%i%%"
  call set "GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE_PTTN=%%GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE_PTTN:{{REPO}}=%%j%%"
  call set "GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE_PTTN=%%GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE_PTTN:{{DATE_TIME}}=????'??'??_??'??'??''???%%"

  rem expansion into a variable
  call set ?.=@dir "%%GH_BACKUP_RESTAPI_REPO_DIR:/=\%%\%%REPO_OWNER%%\%%REPO%%\%%GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE_PTTN%%.*" /A:-D /B /O:-N /S

  call :EXEC_AND_RETURN_FIRST_LINE

  if defined PRINT_BLANK_LINE echo;

  call echo;### %%REPO_OWNER%%/%%REPO%%

  if defined GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE (
    call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/extract_files_from_archives.bat" -i -p "%%GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE%%" * "%%GH_BACKUP_EXTRACT_TEMP_DIR%%" >nul

    call set ?.=@dir "%%GH_BACKUP_EXTRACT_TEMP_DIR:/=\%%\repo\%%REPO_OWNER%%\%%REPO%%\*.json" /A:-D /B /O:D /S

    (
      for /F "usebackq tokens=* delims="eol^= %%k in (`%%?.%%`) do (
        set "JSON_FILE=%%k"
        call "%%?~dp0%%print_repo_workflows_from_restapi_json.bat"%%BARE_FLAGS%% -skip-sort -- "%%JSON_FILE%%" && set /A NUM_PRINTED_JSON_FILES+=1
      )
    ) %REDIR_LINE%

    if %FLAG_SKIP_SORT% EQU 0 call :SORT & type "%INOUT_LIST_FILE_TMP1%"
  )

  set PRINT_BLANK_LINE=1
)

if %NUM_PRINTED_JSON_FILES% NEQ 0 exit /b 0

exit /b -1

:SORT
(
  for /F "usebackq tokens=* delims="eol^= %%i in ("%INOUT_LIST_FILE_TMP0%") do set "URL_PATH=%%i" & call :ENCODE_URL
) > "%INOUT_LIST_FILE_TMP1%"

"%SystemRoot%\System32\sort.exe" /L C "%INOUT_LIST_FILE_TMP1%" /O "%INOUT_LIST_FILE_TMP0%"

(
  for /F "usebackq tokens=* delims="eol^= %%i in ("%INOUT_LIST_FILE_TMP0%") do set "URL_PATH=%%i" & call :DECODE_URL
) > "%INOUT_LIST_FILE_TMP1%"

exit /b 0

:ENCODE_URL
setlocal ENABLEDELAYEDEXPANSION & echo;!URL_PATH:/=/!
exit /b 0

:DECODE_URL
setlocal ENABLEDELAYEDEXPANSION & echo;!URL_PATH:/=/!
exit /b 0

:EXEC_AND_RETURN_FIRST_LINE
set "GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE="
for /F "usebackq tokens=* delims="eol^= %%i in (`%%?.%%`) do (
  set "GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE=%%i"
  exit /b 0
)
exit /b 0
