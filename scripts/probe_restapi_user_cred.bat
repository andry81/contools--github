@echo off & goto DOC_END

rem USAGE:
rem   probe_restapi_user_cred.bat [--] [<USER> [<PASS>]]

rem Description:
rem   Script to probe a user credentials using restapi request.

rem --:
rem   Stop flags parse.

rem <USER>:
rem   User name.
rem <PASS>:
rem   User pass.
:DOC_END

setlocal

call "%%~dp0__init__\script_init.bat" probe restapi %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%" || exit /b

call :MAIN %%*
set LAST_ERROR=%ERRORLEVEL%

:FREE_TEMP_DIR
rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

set /A NEST_LVL-=1

exit /b %LAST_ERROR%

:MAIN
rem script flags

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if not "%FLAG%" == "--" (
    echo;%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP
)

set "USER=%~1"
set "PASS=%~2"

if not defined USER set "USER=%GH_AUTH_USER%"

if not defined USER (
  echo;%?~%: error: USER is not defined.
  exit /b 255
) >&2

if not defined PASS set "PASS=%GH_AUTH_PASS%"

if not defined PASS (
  echo;%?~%: error: PASS is not defined.
  exit /b 255
) >&2

set CURL_BARE_FLAGS=-I

set "GH_PROBE_TEMP_DIR=%SCRIPT_TEMP_CURRENT_DIR%\probe\restapi"

set "GH_PROBE_OUTPUT_TEMP_DIR=%GH_PROBE_TEMP_DIR%/user/%USER%"
set "GH_PROBE_OUTPUT_DIR=%GH_PROBE_DIR%/restapi/user/%USER%"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir.bat" "%%GH_PROBE_OUTPUT_TEMP_DIR%%" >nul || exit /b 255

call set "GH_RESTAPI_USER_CRED_PROBE_URL_PATH=%%GH_RESTAPI_USER_CRED_PROBE_URL:{{USER}}=%USER%%%"

rem set "GH_RESTAPI_USER_CRED_PROBE_URL_PATH=%GH_RESTAPI_USER_CRED_PROBE_URL_PATH%"

set "CURL_OUTPUT_FILE=%GH_PROBE_OUTPUT_TEMP_DIR%/%GH_RESTAPI_USER_CRED_PROBE_FILE%"

set PAGE=0

call set "CURL_OUTPUT_FILE=%%CURL_OUTPUT_FILE:{{PAGE}}=%PAGE%%%"

call "%%CONTOOLS_GITHUB_PROJECT_ROOT%%/tools/curl.bat" "%%USER%%" "%%PASS%%" "%%GH_RESTAPI_USER_CRED_PROBE_URL_PATH%%" || goto MAIN_EXIT
echo;

type "%CURL_OUTPUT_FILE:/=\%"
echo;---
echo;

set /P "HTTP_RESPONSE=" < "%CURL_OUTPUT_FILE%"

rem remove double quotes
set "HTTP_RESPONSE=%HTTP_RESPONSE:"=%"

set "HTTP_TOKEN="
set HTTP_VER=0
set HTTP_CODE=0

for /F "tokens=1,2 delims=	 "eol^= %%i in ("%HTTP_RESPONSE%") do set "HTTP_TOKEN=%%i" & set "HTTP_CODE=%%j"
if defined HTTP_TOKEN for /F "tokens=1,2 delims=/"eol^= %%i in ("%HTTP_TOKEN%") do set "HTTP_TOKEN=%%i" & set "HTTP_VER=%%j"

call set "GH_PROBE_RESTAPI_USER_CRED_FILE=%%GH_PROBE_RESTAPI_USER_CRED_FILE_NAME:{{USER}}=%USER%%%"
call set "GH_PROBE_RESTAPI_USER_CRED_FILE=%%GH_PROBE_RESTAPI_USER_CRED_FILE:{{DATE_TIME}}=%PROJECT_LOG_FILE_NAME_DATE_TIME%%%"

echo;Archiving backup directory...
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%GH_PROBE_OUTPUT_DIR%%" || exit /b
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/add_files_to_archive.bat" "%%GH_PROBE_TEMP_DIR%%" "*" "%%GH_PROBE_OUTPUT_DIR%%/%%GH_PROBE_RESTAPI_USER_CRED_FILE%%.7z" -sdel%%_7ZIP_BARE_FLAGS%% || exit /b 20
echo;

if /i not "%HTTP_TOKEN%" == "http" (
  echo;%?~%: warning: query response is invalid.
  echo;
  exit /b 255
) >&2

if "%HTTP_CODE%" == "200" (
  echo;%?~%: info: user credentials are valid.
  echo;
  exit /b 0
)

if "%HTTP_CODE%" == "401" (
  echo;%?~%: error: user credentials are invalid, expired, or malformed.
  echo;
  exit /b 1
) >&2

if "%HTTP_CODE%" == "403" (
  echo;%?~%: error: user request currently is forbidden.
  echo;
  exit /b 2
) >&2

echo;%?~%: error: query responce has unsupported code: code="%HTTP_CODE%".
echo;

exit /b 3

:MAIN_EXIT
set LAST_ERROR=%ERRORLEVEL%

echo;

exit /b %LAST_ERROR%
