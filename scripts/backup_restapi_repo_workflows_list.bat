@echo off

rem USAGE:
rem   backup_restapi_repo_workflows_list.bat [<Flags>] [--] <OWNER> <REPO>

rem Description:
rem   Script to request restapi response of repository workflows list from a
rem   user account.

rem <Flags>:
rem   --
rem     Stop flags parse.

rem <OWNER>:
rem   Owner name of a repository.
rem <REPO>:
rem   Repository name.

setlocal

call "%%~dp0../__init__/script_init.bat" backup restapi %%0 %%* || exit /b
if %IMPL_MODE%0 EQU 0 exit /b

if defined GH_RESTAPI_BACKUP_USE_TIMEOUT_MS call "%%CONTOOLS_ROOT%%/std/sleep.bat" "%%GH_RESTAPI_BACKUP_USE_TIMEOUT_MS%%"

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

set "OWNER=%~1"
set "REPO=%~2"

if not defined OWNER (
  echo;%?~%: error: OWNER is not defined.
  exit /b 255
) >&2

if not defined REPO (
  echo;%?~%: error: REPO is not defined.
  exit /b 255
) >&2

set "QUERY_TEMP_FILE=%SCRIPT_TEMP_CURRENT_DIR%\query.txt"

set "GH_BACKUP_TEMP_DIR=%SCRIPT_TEMP_CURRENT_DIR%\backup\restapi"

set "GH_BACKUP_OUTPUT_TEMP_DIR=%GH_BACKUP_TEMP_DIR%/repo/%OWNER%/%REPO%"
set "GH_BACKUP_OUTPUT_DIR=%GH_BACKUP_RESTAPI_REPO_DIR%/%OWNER%/%REPO%"

call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir.bat" "%%GH_BACKUP_OUTPUT_TEMP_DIR%%" >nul || exit /b 255

set PAGE=1

:PAGE_LOOP
call set "GH_RESTAPI_USER_REPO_WORKFLOWS_URL_PATH=%%GH_RESTAPI_USER_REPO_WORKFLOWS_URL:{{OWNER}}=%OWNER%%%"
call set "GH_RESTAPI_USER_REPO_WORKFLOWS_URL_PATH=%%GH_RESTAPI_USER_REPO_WORKFLOWS_URL_PATH:{{REPO}}=%REPO%%%"

set "GH_RESTAPI_USER_REPO_WORKFLOWS_URL_PATH=%GH_RESTAPI_USER_REPO_WORKFLOWS_URL_PATH%?per_page=%GH_RESTAPI_PARAM_PER_PAGE%&page=%PAGE%"

set "CURL_OUTPUT_FILE=%GH_BACKUP_OUTPUT_TEMP_DIR%/%GH_RESTAPI_USER_REPO_WORKFLOWS_FILE%"

call set "CURL_OUTPUT_FILE=%%CURL_OUTPUT_FILE:{{PAGE}}=%PAGE%%%"

call "%%CONTOOLS_GITHUB_PROJECT_ROOT%%/tools/curl.bat" "%%GH_AUTH_USER%%" "%%GH_AUTH_PASS%%" "%%GH_RESTAPI_USER_REPO_WORKFLOWS_URL_PATH%%" || goto MAIN_EXIT
echo;

"%JQ_EXECUTABLE%" "length" "%CURL_OUTPUT_FILE%" 2>nul > "%QUERY_TEMP_FILE%"

set QUERY_LEN=0
for /F "usebackq tokens=* delims="eol^= %%i in ("%QUERY_TEMP_FILE%") do set QUERY_LEN=%%i

if not defined QUERY_LEN set QUERY_LEN=0
if "%QUERY_LEN%" == "null" set QUERY_LEN=0

rem just in case
if %PAGE% GTR %GH_RESTAPI_REQ_MAX_PAGE% (
  echo;%?~%: error: too many pages, skip processing.
  goto PAGE_LOOP_END
) >&2

if %QUERY_LEN% GEQ %GH_RESTAPI_PARAM_PER_PAGE% set /A "PAGE+=1" & goto PAGE_LOOP

:PAGE_LOOP_END

if %PAGE% LSS 2 if %QUERY_LEN% EQU 0 (
  echo;%?~%: warning: query response is empty.
  exit /b 255
) >&2

call set "GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE=%%GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE_NAME:{{OWNER}}=%OWNER%%%"
call set "GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE=%%GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE:{{REPO}}=%REPO%%%"
call set "GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE=%%GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE:{{DATE_TIME}}=%PROJECT_LOG_FILE_NAME_DATE_TIME%%%"

echo;Archiving backup directory...
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/mkdir_if_notexist.bat" "%%GH_BACKUP_OUTPUT_DIR%%" && ^
call "%%CONTOOLS_BUILD_TOOLS_ROOT%%/add_files_to_archive.bat" "%%GH_BACKUP_TEMP_DIR%%" "*" "%%GH_BACKUP_OUTPUT_DIR%%/%%GH_BACKUP_RESTAPI_REPO_WORKFLOWS_FILE%%.7z" -sdel%%_7ZIP_BARE_FLAGS%% || exit /b 20
echo;

exit /b 0

:MAIN_EXIT
set LAST_ERROR=%ERRORLEVEL%

echo;

exit /b %LAST_ERROR%
