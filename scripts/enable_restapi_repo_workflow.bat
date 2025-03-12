@echo off

rem USAGE:
rem   enable_restapi_repo_workflow.bat [<Flags>] [--] <OWNER> <REPO> <WORKFLOW_ID>

rem Description:
rem   Script to enable a user repository workflow using restapi request.

rem <Flags>:
rem   --
rem     Stop flags parse.

rem <OWNER>:
rem   Owner name of a repository.
rem <REPO>:
rem   Repository name.
rem <WORKFLOW_ID>:
rem   The ID of the workflow. You can also pass the workflow file name as a
rem   string.

rem GitHub Workflow documentation:
rem   https://docs.github.com/en/rest/actions/workflows

setlocal

call "%%~dp0../__init__/script_init.bat" workflow restapi %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

if defined GH_RESTAPI_WORKFLOW_ENABLE_USE_TIMEOUT_MS call "%%CONTOOLS_ROOT%%/std/sleep.bat" "%%GH_RESTAPI_WORKFLOW_ENABLE_USE_TIMEOUT_MS%%"

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
    echo.%?~%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  if not "%FLAG%" == "--" goto FLAGS_LOOP
)

set "OWNER=%~1"
set "REPO=%~2"
set "WORKFLOW_ID=%~3"

if not defined OWNER (
  echo.%?~%: error: OWNER is not defined.
  exit /b 255
) >&2

if not defined REPO (
  echo.%?~%: error: REPO is not defined.
  exit /b 255
) >&2

if not defined WORKFLOW_ID (
  echo.%?~%: error: WORKFLOW_ID is not defined.
  exit /b 255
) >&2

set CURL_BARE_EXTERNAL_FLAGS=%CURL_BARE_FLAGS%
set CURL_BARE_FLAGS=-X PUT

if defined CURL_BARE_EXTERNAL_FLAGS set CURL_BARE_FLAGS=%CURL_BARE_FLAGS% %CURL_BARE_EXTERNAL_FLAGS%

set "QUERY_TEMP_FILE=%SCRIPT_TEMP_CURRENT_DIR%\query.txt"

set "GH_WORKFLOW_TEMP_DIR=%SCRIPT_TEMP_CURRENT_DIR%\workflow\restapi"

set "GH_WORKFLOW_OUTPUT_TEMP_DIR=%GH_WORKFLOW_TEMP_DIR%/repo/%OWNER%/%REPO%/%WORKFLOW_ID%"
set "GH_WORKFLOW_OUTPUT_DIR=%GH_WORKFLOW_DIR%/restapi/repo/%OWNER%/%REPO%/%WORKFLOW_ID%"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir.bat" "%%GH_WORKFLOW_OUTPUT_TEMP_DIR%%" >nul || exit /b 255

call set "GH_RESTAPI_USER_REPO_ENABLE_WORKFLOW_URL_PATH=%%GH_RESTAPI_USER_REPO_ENABLE_WORKFLOW_URL:{{OWNER}}=%OWNER%%%"
call set "GH_RESTAPI_USER_REPO_ENABLE_WORKFLOW_URL_PATH=%%GH_RESTAPI_USER_REPO_ENABLE_WORKFLOW_URL_PATH:{{REPO}}=%REPO%%%"
call set "GH_RESTAPI_USER_REPO_ENABLE_WORKFLOW_URL_PATH=%%GH_RESTAPI_USER_REPO_ENABLE_WORKFLOW_URL_PATH:{{WORKFLOW_ID}}=%WORKFLOW_ID%%%"

set "GH_RESTAPI_USER_REPO_ENABLE_WORKFLOW_URL_PATH=%GH_RESTAPI_USER_REPO_ENABLE_WORKFLOW_URL_PATH%"

set "CURL_OUTPUT_FILE=%GH_WORKFLOW_OUTPUT_TEMP_DIR%/%GH_RESTAPI_USER_REPO_ENABLE_WORKFLOW_FILE%"

call set "CURL_OUTPUT_FILE=%%CURL_OUTPUT_FILE:{{PAGE}}=%PAGE%%%"

call "%%CONTOOLS_GITHUB_PROJECT_ROOT%%/tools/curl.bat" "%%GH_AUTH_USER%%" "%%GH_AUTH_WORKFLOW_WRITE_PASS%%" "%%GH_RESTAPI_USER_REPO_ENABLE_WORKFLOW_URL_PATH%%" || goto MAIN_EXIT
echo.

"%JQ_EXECUTABLE%" "length" "%CURL_OUTPUT_FILE%" 2>nul > "%QUERY_TEMP_FILE%"

set QUERY_LEN=0
for /F "usebackq tokens=* delims="eol^= %%i in ("%QUERY_TEMP_FILE%") do set QUERY_LEN=%%i

if not defined QUERY_LEN set QUERY_LEN=0
if "%QUERY_LEN%" == "null" set QUERY_LEN=0

if %QUERY_LEN% EQU 0 (
  echo.%?~%: warning: query response is empty.
  exit /b 255
) >&2

call set "GH_ENABLE_RESTAPI_REPO_WORKFLOW_FILE=%%GH_ENABLE_RESTAPI_REPO_WORKFLOW_FILE_NAME:{{OWNER}}=%OWNER%%%"
call set "GH_ENABLE_RESTAPI_REPO_WORKFLOW_FILE=%%GH_ENABLE_RESTAPI_REPO_WORKFLOW_FILE:{{REPO}}=%REPO%%%"
call set "GH_ENABLE_RESTAPI_REPO_WORKFLOW_FILE=%%GH_ENABLE_RESTAPI_REPO_WORKFLOW_FILE:{{WORKFLOW_ID}}=%WORKFLOW_ID%%%"
call set "GH_ENABLE_RESTAPI_REPO_WORKFLOW_FILE=%%GH_ENABLE_RESTAPI_REPO_WORKFLOW_FILE:{{DATE_TIME}}=%PROJECT_LOG_FILE_NAME_DATE_TIME%%%"

echo.Archiving backup directory...
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%GH_WORKFLOW_OUTPUT_DIR%%" && ^
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/add_files_to_archive.bat" "%%GH_WORKFLOW_TEMP_DIR%%" "*" "%%GH_WORKFLOW_OUTPUT_DIR%%/%%GH_ENABLE_RESTAPI_REPO_WORKFLOW_FILE%%.7z" -sdel%%_7ZIP_BARE_FLAGS%% || exit /b 20
echo.

exit /b 0

:MAIN_EXIT
set LAST_ERROR=%ERRORLEVEL%

echo.

exit /b %LAST_ERROR%
