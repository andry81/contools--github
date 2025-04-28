@echo off

setlocal DISABLEDELAYEDEXPANSION

set "USER=%~1"
set "PASS=%~2"

if not defined CURL_BARE_FLAGS goto SKIP_CURL_BARE_FLAGS_SHIFT

if not "%CURL_BARE_FLAGS:~0,1%" == " " set CURL_BARE_FLAGS= %CURL_BARE_FLAGS%

:SKIP_CURL_BARE_FLAGS_SHIFT

if %HAS_AUTH_USER%0 NEQ 0 goto SKIP_USER_AUTH_CHECK
if defined USER if not "%USER%" == "{{USER}}" set HAS_AUTH_USER=1

:SKIP_USER_AUTH_CHECK

if %HAS_AUTH_USER%0 NEQ 0 set CURL_BARE_FLAGS=%CURL_BARE_FLAGS% --user "%USER%:%PASS%"

call "%%CONTOOLS_ROOT%%/std/get_cmdline.bat" "%%CURL_EXECUTABLE%%"%%CURL_BARE_FLAGS%%

setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!RETURN_VALUE!") do endlocal & set "CURL_CMDLINE_PREFIX=%%i"

call "%%CONTOOLS_ROOT%%/std/get_cmdline_var_len.bat" -exe CURL_CMDLINE_PREFIX

set /A SKIP_COUNT=%ERRORLEVEL%

call "%%CONTOOLS_ROOT%%/std/setshift.bat" -skip %%SKIP_COUNT%% 2 CURL_CMDLINE %%CURL_CMDLINE_PREFIX%% %%*

setlocal ENABLEDELAYEDEXPANSION & for /F "tokens=* delims="eol^= %%i in ("!CURL_CMDLINE!") do endlocal & (
  echo;^>%%i
  (
    %%i
  ) > "%CURL_OUTPUT_FILE%"
)
exit /b
