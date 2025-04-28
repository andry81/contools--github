@echo off

rem USAGE:
rem   print_repo_from_restapi_json.bat [<Flags>] [--] <JSON_FILE>

rem Description:
rem   Script prints repository fields from the json file.

rem <Flags>:
rem   --
rem     Stop flags parse.
rem   -skip-sort
rem     Skip repositories list alphabetic sort and print as is from the json
rem     file.
rem   -print-full-name
rem     Print `full_name` field. By default `html_url` prints.
rem   -no-url-domain-remove
rem     Don't remove url domain (`https://github.com/`) from the output in
rem     case of print the URL field.
rem   -filter-source
rem     Filter "source" repositories only.
rem   -filter-forked
rem     Filter forked repositories only.
rem   -filter-auth
rem     Filter authenticated repositories only.
rem     Has no effect if `-filter-forked` is used.
rem   -filter-parent
rem     Filter parent repositories only.
rem   -comment-private
rem     Comment private repositories.
rem     Has no effect if `-filter-auth` is used.

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
set FLAG_PRINT_FULL_NAME=0
set FLAG_NO_URL_DOMAIN_REMOVE=0
set FLAG_FILTER_SOURCE=0
set FLAG_FILTER_FORKED=0
set FLAG_FILTER_AUTH=0
set FLAG_FILTER_PARENT=0
set FLAG_COMMENT_PRIVATE=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-skip-sort" (
    set FLAG_SKIP_SORT=1
  ) else if "%FLAG%" == "-print-full-name" (
    set FLAG_PRINT_FULL_NAME=1
  ) else if "%FLAG%" == "-no-url-domain-remove" (
    set FLAG_NO_URL_DOMAIN_REMOVE=1
  ) else if "%FLAG%" == "-filter-source" (
    set FLAG_FILTER_SOURCE=1
  ) else if "%FLAG%" == "-filter-forked" (
    set FLAG_FILTER_FORKED=1
  ) else if "%FLAG%" == "-filter-auth" (
    set FLAG_FILTER_AUTH=1
  ) else if "%FLAG%" == "-filter-parent" (
    set FLAG_FILTER_PARENT=1
  ) else if "%FLAG%" == "-comment-private" (
    set FLAG_COMMENT_PRIVATE=1
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
set "INOUT_LIST_FILE_TMP2=%SCRIPT_TEMP_CURRENT_DIR%\inout2.lst"

set "JSON_FILE=%~1"

if not defined JSON_FILE (
  echo;%?~%: error: JSON_FILE is not defined.
  exit /b 255
) >&2

if not exist "%JSON_FILE%" (
  echo;%?~%: error: JSON_FILE is not found: "%JSON_FILE%".
  exit /b 255
) >&2

if %FLAG_PRINT_FULL_NAME% EQU 0 (
  set "PRINT_FIELD_NAME=html_url"
) else set "PRINT_FIELD_NAME=full_name"

if %FLAG_FILTER_PARENT% EQU 0 (
  set "FILTER_PARENT_EXPR=.[]"
) else set "FILTER_PARENT_EXPR=.parent"

if %FLAG_FILTER_AUTH% EQU 0 (
  set "FILTER_AUTH_EXPR="
) else (
  set "FILTER_AUTH_EXPR= | select(.private != false)"
  set "FLAG_COMMENT_PRIVATE=0"
)

rem Docs: https://jqlang.github.io/jq/manual/v1.6/#assignment
if %FLAG_COMMENT_PRIVATE% EQU 0 (
  set "FILTER_FIELD_EXPR=.%PRINT_FIELD_NAME%"
) else set "FILTER_FIELD_EXPR= | if .private != false then \"#\" + .%PRINT_FIELD_NAME% else .%PRINT_FIELD_NAME% end"

if %FLAG_FILTER_SOURCE% EQU 0 (
  if %FLAG_FILTER_FORKED% EQU 0 (
    set "JQ_EXPR=%FILTER_PARENT_EXPR%%FILTER_AUTH_EXPR%%FILTER_FIELD_EXPR%"
  ) else set "JQ_EXPR=%FILTER_PARENT_EXPR% | select(.fork != false).%PRINT_FIELD_NAME%"
) else set "JQ_EXPR=%FILTER_PARENT_EXPR% | select(.fork == false)%FILTER_AUTH_EXPR%%FILTER_FIELD_EXPR%"

"%JQ_EXECUTABLE%" -c -r "%JQ_EXPR%" "%JSON_FILE%" > "%INOUT_LIST_FILE_TMP0%" || exit /b

set "INPUT_LIST_FILE=%INOUT_LIST_FILE_TMP0%"

if %FLAG_SKIP_SORT% NEQ 0 goto SKIP_SORT

(
  for /F "usebackq tokens=* delims="eol^= %%i in ("%INOUT_LIST_FILE_TMP0%") do set "URL_PATH=%%i" & call :ENCODE_URL
) > "%INOUT_LIST_FILE_TMP1%"

"%SystemRoot%\System32\sort.exe" /L C "%INOUT_LIST_FILE_TMP1%" /O "%INOUT_LIST_FILE_TMP0%"

(
  for /F "usebackq tokens=* delims="eol^= %%i in ("%INOUT_LIST_FILE_TMP0%") do set "URL_PATH=%%i" & call :DECODE_URL
) > "%INOUT_LIST_FILE_TMP1%"

set "INPUT_LIST_FILE=%INOUT_LIST_FILE_TMP1%"

goto SORT_END

:ENCODE_URL
setlocal ENABLEDELAYEDEXPANSION & (echo;!URL_PATH:/=/!)
exit /b 0

:DECODE_URL
setlocal ENABLEDELAYEDEXPANSION & (echo;!URL_PATH:/=/!)
exit /b 0

:SORT_END
:SKIP_SORT
if %FLAG_PRINT_FULL_NAME% NEQ 0 goto NO_URL_DOMAIN_REMOVE
if %FLAG_NO_URL_DOMAIN_REMOVE% NEQ 0 goto NO_URL_DOMAIN_REMOVE

(
  for /F "usebackq tokens=* delims="eol^= %%i in ("%INPUT_LIST_FILE%") do set "URL_PATH=%%i" & call :PROCESS_URL
) > "%INOUT_LIST_FILE_TMP2%"

type "%INOUT_LIST_FILE_TMP2%"

exit /b 0

:PROCESS_URL
if "%URL_PATH:~0,19%" == "https://github.com/" set "URL_PATH=%URL_PATH:~19%"
if defined URL_PATH setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!URL_PATH!") do endlocal & echo;%%i
exit /b

:NO_URL_DOMAIN_REMOVE
type "%INPUT_LIST_FILE%"

exit /b 0
